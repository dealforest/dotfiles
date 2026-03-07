#!/usr/bin/env python3
"""
Flowchart SVG Generator – iteration 7 (Sugiyama layout)

Generates Visio-style swimlane flowcharts from an intermediate JSON format.
No external dependencies — Python standard library only.

Key features (iteration 7):
- Sugiyama hierarchical graph layout algorithm for optimal node placement
- ALL lines strictly 90-degree (horizontal + vertical only, no diagonals)
- Swimlane-constrained layout with barycenter crossing minimization
- Terminal end-nodes in the same participant placed side-by-side
- CJK-aware text wrapping (fullwidth chars counted as 2)
- Dynamic box/pill width based on text length
- Smart branch routing (exit from the side closest to target)
- Track-based horizontal arrow routing (no line overlap)
"""

import json, sys, html, unicodedata
from typing import List, Dict, Optional, Tuple, Set
from dataclasses import dataclass
from collections import defaultdict, deque

# ═══════════════════════════════════════════════════════════════════════
#  Design Constants
# ═══════════════════════════════════════════════════════════════════════

COLORS = {
    "background": "#F7F7F7", "lane_border": "#CCCCCC",
    "lane_bg": "#FFFFFF", "lane_header_bg": "#4A90E2",
    "lane_header_text": "#FFFFFF",
    "process_border": "#4A90E2", "process_bg": "#FFFFFF",
    "internal_bg": "#E8F1FF", "internal_border": "#4A90E2",
    "external_bg": "#E9F7EC", "external_border": "#4A90E2",
    "condition_border": "#7B61FF", "condition_bg": "#FFFFFF",
    "arrow": "#555555", "arrow_label": "#444444",
    "arrow_label_bg": "#F7F7F7", "text": "#333333",
    "start_end_bg": "#4A90E2", "start_end_text": "#FFFFFF",
    "icon_stroke": "#666666",
}

FONTS = {
    "family": "Segoe UI, Helvetica, 'Noto Sans', Arial, sans-serif",
    "size_normal": 14, "size_label": 11, "size_header": 15,
}

L = {  # Layout constants
    "lane_pad": 30, "header_h": 44,
    "min_box_w": 180, "box_h": 56, "box_r": 10,
    "diamond": 76, "step_gap": 55,
    "margin_top": 24, "margin_bot": 40, "margin_side": 24,
    "arrow_hs": 7, "icon": 16, "icon_ox": 10, "icon_oy": 10,
    "shadow_dx": 2, "shadow_blur": 4,
    "pill_h": 40, "pill_pad": 30,
    "branch_gap": 25, "track_spacing": 14,
    "max_vw": 18, "no_offset": 0.3,
    "terminal_gap": 24,
}

# ═══════════════════════════════════════════════════════════════════════
#  CJK-Aware Text
# ═══════════════════════════════════════════════════════════════════════

def _cw(ch): return 2 if unicodedata.east_asian_width(ch) in ('F','W') else 1
def _vw(s): return sum(_cw(c) for c in s)

def _px(s, fs):
    """Estimate pixel width."""
    return sum(fs if unicodedata.east_asian_width(c) in ('F','W') else fs*0.55 for c in s)

def _wrap(text, max_vw=18):
    if _vw(text) <= max_vw: return [text]
    lines, cur, cw_ = [], "", 0
    for ch in text:
        w = _cw(ch)
        if cw_ + w > max_vw and cur:
            lines.append(cur); cur, cw_ = ch, w
        else:
            cur += ch; cw_ += w
    if cur: lines.append(cur)
    return lines

def _box_w(text, fs, icon_area=34, pad=20):
    lines = _wrap(text, L["max_vw"])
    max_px = max(_px(line, fs) for line in lines)
    return max(L["min_box_w"], max_px + icon_area + pad)

def _pill_w(text, fs, pad=None):
    """Dynamic pill width based on text."""
    if pad is None: pad = L["pill_pad"]
    px = _px(text, fs)
    return max(L["min_box_w"] * 0.8, px + pad * 2)

# ═══════════════════════════════════════════════════════════════════════
#  SVG Text Rendering
# ═══════════════════════════════════════════════════════════════════════

def _svg_text(x, y, text, fs, fill="#333", anchor="middle", max_vw=18, bold=False):
    lines = _wrap(text, max_vw)
    lh = fs * 1.3
    sy = y - (len(lines)-1)*lh/2
    wt = "600" if bold else "normal"
    return "\n".join(
        f'<text x="{x}" y="{sy+i*lh}" text-anchor="{anchor}" '
        f'dominant-baseline="central" font-family="{FONTS["family"]}" '
        f'font-size="{fs}" font-weight="{wt}" fill="{fill}">'
        f'{html.escape(line)}</text>'
        for i, line in enumerate(lines))

def _label(x, y, text, anchor="middle"):
    fs = FONTS["size_label"]
    tw, th = _px(text, fs), fs + 4
    rx = x - tw/2 if anchor == "middle" else x
    return "\n".join([
        f'<rect x="{rx-3}" y="{y-th/2}" width="{tw+6}" height="{th}" rx="3" '
        f'fill="{COLORS["arrow_label_bg"]}" opacity="0.9"/>',
        f'<text x="{x}" y="{y}" text-anchor="{anchor}" dominant-baseline="central" '
        f'font-family="{FONTS["family"]}" font-size="{fs}" '
        f'fill="{COLORS["arrow_label"]}">{html.escape(text)}</text>'])

# ═══════════════════════════════════════════════════════════════════════
#  Icons
# ═══════════════════════════════════════════════════════════════════════

def _icon(name, x, y, s=16):
    sk, sw = COLORS["icon_stroke"], "1.5"
    I = {
     "user": f'<circle cx="{s/2}" cy="{s*.32}" r="{s*.22}" fill="none" stroke="{sk}" stroke-width="{sw}"/><path d="M{s*.1},{s*.95}Q{s*.1},{s*.55} {s/2},{s*.55}Q{s*.9},{s*.55} {s*.9},{s*.95}" fill="none" stroke="{sk}" stroke-width="{sw}"/>',
     "server": f'<rect x="1" y="1" width="{s-2}" height="{s-2}" rx="2" fill="none" stroke="{sk}" stroke-width="{sw}"/><line x1="1" y1="{s*.35}" x2="{s-1}" y2="{s*.35}" stroke="{sk}" stroke-width="{sw}"/><line x1="1" y1="{s*.65}" x2="{s-1}" y2="{s*.65}" stroke="{sk}" stroke-width="{sw}"/>',
     "database": f'<ellipse cx="{s/2}" cy="{s*.2}" rx="{s*.4}" ry="{s*.15}" fill="none" stroke="{sk}" stroke-width="{sw}"/><path d="M{s*.1},{s*.2}L{s*.1},{s*.8}" fill="none" stroke="{sk}" stroke-width="{sw}"/><path d="M{s*.9},{s*.2}L{s*.9},{s*.8}" fill="none" stroke="{sk}" stroke-width="{sw}"/><ellipse cx="{s/2}" cy="{s*.8}" rx="{s*.4}" ry="{s*.15}" fill="none" stroke="{sk}" stroke-width="{sw}"/>',
     "ai": f'<circle cx="{s/2}" cy="{s/2}" r="{s*.4}" fill="none" stroke="{sk}" stroke-width="{sw}"/><circle cx="{s/2}" cy="{s*.35}" r="1.5" fill="{sk}"/><circle cx="{s*.35}" cy="{s*.6}" r="1.5" fill="{sk}"/><circle cx="{s*.65}" cy="{s*.6}" r="1.5" fill="{sk}"/>',
     "cloud": f'<path d="M{s*.2},{s*.7}Q{s*.05},{s*.7} {s*.05},{s*.55}Q{s*.05},{s*.35} {s*.25},{s*.35}Q{s*.25},{s*.2} {s*.45},{s*.2}Q{s*.6},{s*.2} {s*.65},{s*.3}Q{s*.85},{s*.25} {s*.9},{s*.45}Q{s*.95},{s*.6} {s*.8},{s*.7}Z" fill="none" stroke="{sk}" stroke-width="{sw}"/>',
     "mobile": f'<rect x="{s*.25}" y="1" width="{s*.5}" height="{s-2}" rx="3" fill="none" stroke="{sk}" stroke-width="{sw}"/><line x1="{s*.35}" y1="{s*.15}" x2="{s*.65}" y2="{s*.15}" stroke="{sk}" stroke-width="1"/><circle cx="{s/2}" cy="{s*.85}" r="1.5" fill="{sk}"/>',
     "payment": f'<rect x="1" y="{s*.2}" width="{s-2}" height="{s*.6}" rx="2" fill="none" stroke="{sk}" stroke-width="{sw}"/><line x1="1" y1="{s*.4}" x2="{s-1}" y2="{s*.4}" stroke="{sk}" stroke-width="{sw}"/>',
     "email": f'<rect x="1" y="{s*.2}" width="{s-2}" height="{s*.6}" rx="1" fill="none" stroke="{sk}" stroke-width="{sw}"/><polyline points="1,{s*.2} {s/2},{s*.55} {s-1},{s*.2}" fill="none" stroke="{sk}" stroke-width="{sw}"/>',
     "shield": f'<path d="M{s/2},1L{s*.85},{s*.2}L{s*.85},{s*.55}Q{s*.85},{s*.85} {s/2},{s-1}Q{s*.15},{s*.85} {s*.15},{s*.55}L{s*.15},{s*.2}Z" fill="none" stroke="{sk}" stroke-width="{sw}"/>',
     "gear": f'<circle cx="{s/2}" cy="{s/2}" r="{s*.2}" fill="none" stroke="{sk}" stroke-width="{sw}"/><circle cx="{s/2}" cy="{s/2}" r="{s*.38}" fill="none" stroke="{sk}" stroke-width="{sw}" stroke-dasharray="4 3"/>',
     "document": f'<path d="M{s*.2},1L{s*.6},1L{s*.8},{s*.2}L{s*.8},{s-1}L{s*.2},{s-1}Z" fill="none" stroke="{sk}" stroke-width="{sw}"/><line x1="{s*.3}" y1="{s*.4}" x2="{s*.7}" y2="{s*.4}" stroke="{sk}" stroke-width="1"/><line x1="{s*.3}" y1="{s*.55}" x2="{s*.7}" y2="{s*.55}" stroke="{sk}" stroke-width="1"/>',
     "clock": f'<circle cx="{s/2}" cy="{s/2}" r="{s*.4}" fill="none" stroke="{sk}" stroke-width="{sw}"/><line x1="{s/2}" y1="{s/2}" x2="{s/2}" y2="{s*.25}" stroke="{sk}" stroke-width="{sw}"/>',
    }
    inner = I.get(name, I["gear"])
    return f'<g transform="translate({x},{y})">{inner}</g>'

# ═══════════════════════════════════════════════════════════════════════
#  Track Allocator — prevents horizontal arrow segments from overlapping
# ═══════════════════════════════════════════════════════════════════════

class TrackAlloc:
    def __init__(self, step_pos: dict):
        self.used = []  # (y, x_min, x_max)
        self.step_pos = step_pos

    def alloc(self, ideal_y: float, x1: float, x2: float) -> float:
        xmin, xmax = min(x1, x2), max(x1, x2)
        sp = L["track_spacing"]
        y = ideal_y
        for _ in range(40):
            if not self._conflicts(y, xmin, xmax, sp):
                self.used.append((y, xmin, xmax))
                return y
            y += sp
        self.used.append((y, xmin, xmax))
        return y

    def _conflicts(self, y, xmin, xmax, sp):
        # Check conflict with other tracks
        for ty, tx0, tx1 in self.used:
            if abs(y - ty) < sp and not (xmax < tx0 - 5 or xmin > tx1 + 5):
                return True
        # Check conflict with shapes
        for pos in self.step_pos.values():
            if pos["top"] - 4 <= y <= pos["bottom"] + 4:
                if not (xmax < pos["left"] - 5 or xmin > pos["right"] + 5):
                    return True
        return False

# ═══════════════════════════════════════════════════════════════════════
#  Arrow Drawing Primitives
# ═══════════════════════════════════════════════════════════════════════

def _arrow_defs():
    hs = L["arrow_hs"]
    return (f'<marker id="ah" markerWidth="{hs}" markerHeight="{hs}" '
            f'refX="{hs}" refY="{hs/2}" orient="auto" markerUnits="userSpaceOnUse">'
            f'<polygon points="0 0,{hs} {hs/2},0 {hs}" fill="{COLORS["arrow"]}"/></marker>')

def _pl(pts):
    """Polyline arrow through waypoints — all segments must be 90-degree."""
    p = " ".join(f"{x},{y}" for x, y in pts)
    return (f'<polyline points="{p}" fill="none" stroke="{COLORS["arrow"]}" '
            f'stroke-width="1.5" marker-end="url(#ah)"/>')

def _straight(x1, y1, x2, y2):
    return (f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" '
            f'stroke="{COLORS["arrow"]}" stroke-width="1.5" marker-end="url(#ah)"/>')

# ═══════════════════════════════════════════════════════════════════════
#  Shape Drawing
# ═══════════════════════════════════════════════════════════════════════

def _box(x, y, w, h, text, stype, icon_name="gear"):
    r = L["box_r"]
    bg = {"process": COLORS["process_bg"], "internal": COLORS["internal_bg"],
          "external": COLORS["external_bg"]}.get(stype, COLORS["process_bg"])
    parts = [
        f'<rect x="{x+L["shadow_dx"]}" y="{y+L["shadow_dx"]}" width="{w}" height="{h}" '
        f'rx="{r}" fill="rgba(0,0,0,0.06)" filter="url(#shadow)"/>',
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" '
        f'fill="{bg}" stroke="{COLORS["process_border"]}" stroke-width="1.5"/>',
        _icon(icon_name, x+L["icon_ox"], y+L["icon_oy"], L["icon"]),
    ]
    tl = x + L["icon_ox"] + L["icon"] + 6
    tr = x + w - 8
    tx = (tl + tr) / 2
    mvw = int(((tr - tl) / FONTS["size_normal"]) * 2)
    parts.append(_svg_text(tx, y+h/2, text, FONTS["size_normal"],
                           fill=COLORS["text"], max_vw=mvw))
    return "\n".join(parts)

def _diamond(x, y, s, text):
    import math
    cx, cy = x+s/2, y+s/2
    pts = f"{cx},{y} {x+s},{cy} {cx},{y+s} {x},{cy}"
    # Inscribed rectangle width = s / √2; compute max_vw from that
    inscribed_w = s / math.sqrt(2) - 8  # small padding
    fs = FONTS["size_label"]
    max_vw = max(12, int((inscribed_w / (fs * 0.55)) * 1.0))
    return "\n".join([
        f'<polygon points="{pts}" fill="{COLORS["condition_bg"]}" '
        f'stroke="{COLORS["condition_border"]}" stroke-width="2"/>',
        _svg_text(cx, cy, text, FONTS["size_label"], fill=COLORS["text"],
                  max_vw=max_vw, bold=True)])

def _pill(x, y, w, h, text):
    r = h / 2
    return "\n".join([
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" '
        f'fill="{COLORS["start_end_bg"]}" stroke="{COLORS["start_end_bg"]}"/>',
        _svg_text(x+w/2, y+h/2, text, FONTS["size_normal"],
                  fill=COLORS["start_end_text"], max_vw=24, bold=True)])

# ═══════════════════════════════════════════════════════════════════════
#  Sugiyama Layout Engine — Data Structures
# ═══════════════════════════════════════════════════════════════════════

@dataclass
class EdgeRoute:
    """Routed edge with 90-degree-only waypoints."""
    from_id: str
    to_id: str
    waypoints: List[Tuple[float, float]]
    label: Optional[str] = None
    label_pos: Optional[Tuple[float, float]] = None
    label_anchor: str = "middle"
    branch: Optional[str] = None


class LayoutGraph:
    """Graph data structure for the Sugiyama hierarchical layout pipeline."""

    def __init__(self):
        self.nodes: Dict[str, dict] = {}
        self.edges: List[dict] = []
        self.succ: Dict[str, List[str]] = defaultdict(list)
        self.pred: Dict[str, List[str]] = defaultdict(list)
        self.lane_order: List[str] = []
        self.layer: Dict[str, int] = {}
        self.order: Dict[int, List[str]] = defaultdict(list)
        self.x: Dict[str, float] = {}
        self.y: Dict[str, float] = {}
        self._dummy_count = 0

    def add_node(self, nid, participant, ntype, text, w, h, is_dummy=False):
        self.nodes[nid] = {
            "participant": participant, "type": ntype, "text": text,
            "w": w, "h": h, "is_dummy": is_dummy,
        }

    def add_edge(self, from_id, to_id, label=None, branch=None):
        if from_id in self.nodes and to_id in self.nodes:
            self.edges.append({
                "from": from_id, "to": to_id,
                "label": label, "branch": branch,
                "is_reversed": False,
            })
            self.succ[from_id].append(to_id)
            self.pred[to_id].append(from_id)

# ═══════════════════════════════════════════════════════════════════════
#  Sugiyama Phase 1: Cycle Removal
# ═══════════════════════════════════════════════════════════════════════

def _separate_components(g: LayoutGraph):
    """Detect connected components via BFS and offset layers so they don't overlap."""
    # Build undirected adjacency
    adj: Dict[str, Set[str]] = defaultdict(set)
    for u in g.nodes:
        for v in g.succ[u]:
            adj[u].add(v)
            adj[v].add(u)
        for v in g.pred[u]:
            adj[u].add(v)
            adj[v].add(u)

    visited: Set[str] = set()
    components: List[List[str]] = []

    for n in g.nodes:
        if n in visited:
            continue
        comp: List[str] = []
        queue = deque([n])
        visited.add(n)
        while queue:
            u = queue.popleft()
            comp.append(u)
            for v in adj[u]:
                if v not in visited and v in g.nodes:
                    visited.add(v)
                    queue.append(v)
        components.append(comp)

    if len(components) <= 1:
        return

    # Sort components so that the one with the most edges into the graph comes first
    # (heuristic: keep the largest component first)
    components.sort(key=lambda c: len(c), reverse=True)

    # Offset layers: each component starts after the previous one ends
    layer_offset = 0
    for comp in components:
        # Current min layer in this component
        min_layer = min(g.layer.get(n, 0) for n in comp)
        shift = layer_offset - min_layer
        if shift != 0:
            for n in comp:
                g.layer[n] = g.layer.get(n, 0) + shift
        max_layer = max(g.layer.get(n, 0) for n in comp)
        layer_offset = max_layer + 1

    # Rebuild order from adjusted layers
    g.order = defaultdict(list)
    # Use topological order to maintain consistency
    in_deg = {n: len(g.pred[n]) for n in g.nodes}
    queue = deque(n for n, d in in_deg.items() if d == 0)
    topo: List[str] = []
    while queue:
        u = queue.popleft()
        topo.append(u)
        for v in g.succ[u]:
            in_deg[v] -= 1
            if in_deg[v] == 0:
                queue.append(v)
    seen = set(topo)
    for n in g.nodes:
        if n not in seen:
            topo.append(n)
    for n in topo:
        g.order[g.layer[n]].append(n)


def _remove_cycles(g: LayoutGraph):
    """DFS-based cycle removal by reversing back edges."""
    WHITE, GRAY, BLACK = 0, 1, 2
    color = {n: WHITE for n in g.nodes}

    def dfs(u):
        color[u] = GRAY
        for v in list(g.succ[u]):
            if color[v] == GRAY:
                # Back edge — reverse it
                g.succ[u].remove(v)
                g.pred[v].remove(u)
                g.succ[v].append(u)
                g.pred[u].append(v)
                for e in g.edges:
                    if e["from"] == u and e["to"] == v and not e["is_reversed"]:
                        e["from"], e["to"] = v, u
                        e["is_reversed"] = True
                        break
            elif color[v] == WHITE:
                dfs(v)
        color[u] = BLACK

    for n in g.nodes:
        if color[n] == WHITE:
            dfs(n)

# ═══════════════════════════════════════════════════════════════════════
#  Sugiyama Phase 2: Layer Assignment
# ═══════════════════════════════════════════════════════════════════════

def _assign_layers(g: LayoutGraph):
    """Longest-path layering from source nodes."""
    # Topological sort (Kahn's algorithm)
    in_deg = {n: len(g.pred[n]) for n in g.nodes}
    queue = deque(n for n, d in in_deg.items() if d == 0)
    topo: List[str] = []
    while queue:
        u = queue.popleft()
        topo.append(u)
        for v in g.succ[u]:
            in_deg[v] -= 1
            if in_deg[v] == 0:
                queue.append(v)

    # Safety: append any remaining nodes (shouldn't happen after cycle removal)
    seen = set(topo)
    for n in g.nodes:
        if n not in seen:
            topo.append(n)

    # Longest path from source
    dist: Dict[str, int] = {n: 0 for n in g.nodes}
    for u in topo:
        for v in g.succ[u]:
            dist[v] = max(dist[v], dist[u] + 1)

    g.layer = dist
    max_layer = max(dist.values()) if dist else 0
    g.order = defaultdict(list)
    for u in topo:
        g.order[dist[u]].append(u)


def _align_end_nodes(g: LayoutGraph, steps):
    """Push end-type nodes in the same participant to the same (max) layer."""
    end_by_part: Dict[str, List[str]] = defaultdict(list)
    for s in steps:
        if s["type"] == "end" and s["id"] in g.nodes:
            end_by_part[s["participant"]].append(s["id"])

    for pid, nids in end_by_part.items():
        if len(nids) >= 2:
            max_l = max(g.layer[n] for n in nids)
            for n in nids:
                old_l = g.layer[n]
                if old_l != max_l:
                    if n in g.order[old_l]:
                        g.order[old_l].remove(n)
                    g.layer[n] = max_l
                    if n not in g.order[max_l]:
                        g.order[max_l].append(n)


def _insert_dummy_nodes(g: LayoutGraph):
    """Insert dummy nodes for edges spanning > 1 layer."""
    new_edges: List[dict] = []

    for e in list(g.edges):
        u, v = e["from"], e["to"]
        lu, lv = g.layer[u], g.layer[v]
        span = lv - lu

        if span <= 1:
            new_edges.append(e)
            continue

        # Remove direct edge from adjacency
        if v in g.succ[u]:
            g.succ[u].remove(v)
        if u in g.pred[v]:
            g.pred[v].remove(u)

        prev = u
        participant = g.nodes[u]["participant"]

        for k in range(1, span):
            did = f"__d{g._dummy_count}"
            g._dummy_count += 1
            g.add_node(did, participant, "dummy", "", 0, 0, is_dummy=True)
            g.layer[did] = lu + k
            g.order[lu + k].append(did)

            lbl = e["label"] if k == 1 else None
            br = e["branch"] if k == 1 else None
            new_edges.append({
                "from": prev, "to": did,
                "label": lbl, "branch": br,
                "is_reversed": e.get("is_reversed", False),
            })
            g.succ[prev].append(did)
            g.pred[did].append(prev)
            prev = did

        # Final edge: last dummy → v
        new_edges.append({
            "from": prev, "to": v,
            "label": None, "branch": None,
            "is_reversed": e.get("is_reversed", False),
        })
        g.succ[prev].append(v)
        g.pred[v].append(prev)

    g.edges = new_edges

# ═══════════════════════════════════════════════════════════════════════
#  Sugiyama Phase 3: Crossing Minimization
# ═══════════════════════════════════════════════════════════════════════

def _minimize_crossings(g: LayoutGraph):
    """Barycenter method with swimlane constraints."""
    if not g.order:
        return
    max_layer = max(g.order.keys())

    # Identify yes-branch targets for tie-breaking (yes before no)
    yes_targets: Set[str] = set()
    for e in g.edges:
        if e.get("branch") == "yes":
            yes_targets.add(e["to"])

    def sort_layer(layer_idx, ref_idx, use_pred=True):
        """Sort nodes in layer_idx by barycenter w.r.t. reference layer."""
        layer = g.order[layer_idx]
        ref = g.order[ref_idx]
        ref_pos = {n: i for i, n in enumerate(ref)}

        # Group by lane
        lane_groups: Dict[str, List[str]] = defaultdict(list)
        for n in layer:
            lane_groups[g.nodes[n]["participant"]].append(n)

        # Sort each lane group by barycenter
        for lid, nodes in lane_groups.items():
            bary: Dict[str, float] = {}
            for n in nodes:
                neighbors = g.pred[n] if use_pred else g.succ[n]
                positions = [ref_pos[nb] for nb in neighbors if nb in ref_pos]
                bary[n] = sum(positions) / len(positions) if positions else float('inf')

            lane_groups[lid] = sorted(nodes, key=lambda n: (
                bary[n],
                0 if n in yes_targets else 1,  # yes branch first
            ))

        # Reassemble in lane order
        new_order: List[str] = []
        for lid in g.lane_order:
            new_order.extend(lane_groups.get(lid, []))
        g.order[layer_idx] = new_order

    # 4 passes: 2× (top→bottom + bottom→top)
    for _ in range(2):
        for i in range(1, max_layer + 1):
            sort_layer(i, i - 1, use_pred=True)
        for i in range(max_layer - 1, -1, -1):
            sort_layer(i, i + 1, use_pred=False)

# ═══════════════════════════════════════════════════════════════════════
#  Sugiyama Phase 4: Coordinate Assignment
# ═══════════════════════════════════════════════════════════════════════

def _assign_coordinates(g: LayoutGraph, lane_x: dict):
    """Assign x,y using lane centres and layer heights. Returns total_h."""
    if not g.order:
        return L["margin_top"] + L["header_h"] + L["margin_bot"]
    max_layer = max(g.order.keys())

    # Y for each layer (based on tallest real node in that layer)
    layer_y: Dict[int, float] = {}
    cy = L["margin_top"] + L["header_h"] + L["step_gap"]

    for li in range(max_layer + 1):
        layer_y[li] = cy
        max_h = 0
        for nid in g.order[li]:
            node = g.nodes[nid]
            if not node["is_dummy"]:
                max_h = max(max_h, node["h"])
        cy += (max_h if max_h > 0 else 10) + L["step_gap"]

    # Assign X,Y per node
    for li in range(max_layer + 1):
        # Group real nodes by lane
        lane_nodes: Dict[str, List[str]] = defaultdict(list)
        for nid in g.order[li]:
            if g.nodes[nid]["is_dummy"]:
                lane = lane_x[g.nodes[nid]["participant"]]
                g.x[nid] = lane["center"]
                g.y[nid] = layer_y[li]
            else:
                lane_nodes[g.nodes[nid]["participant"]].append(nid)

        for lid, nodes in lane_nodes.items():
            lane = lane_x[lid]
            if len(nodes) == 1:
                nid = nodes[0]
                g.x[nid] = lane["center"]
                g.y[nid] = layer_y[li]
            else:
                # Multiple nodes side-by-side within the lane
                total_w = sum(g.nodes[n]["w"] for n in nodes)
                gap = L["terminal_gap"]
                total_w += (len(nodes) - 1) * gap
                start_cx = lane["center"] - total_w / 2
                for nid in nodes:
                    w = g.nodes[nid]["w"]
                    g.x[nid] = start_cx + w / 2
                    g.y[nid] = layer_y[li]
                    start_cx += w + gap

    return cy + L["margin_bot"]

# ═══════════════════════════════════════════════════════════════════════
#  Phase 5: Orthogonal Edge Router
# ═══════════════════════════════════════════════════════════════════════

class OrthogonalRouter:
    """Routes all edges with strictly 90-degree segments."""

    def __init__(self, spos, lane_x, smap, arrows=None):
        self.spos = spos
        self.lane_x = lane_x
        self.smap = smap
        self.ta = TrackAlloc(spos)
        # Build successor map and precompute branch depths for smart routing
        self._arrows = arrows or []
        self._succ: Dict[str, List[str]] = defaultdict(list)
        for a in self._arrows:
            self._succ[a["from"]].append(a["to"])
        self._depth_cache: Dict[str, int] = {}
        # Precompute which branch of each condition should go straight down
        self._straight_branch = self._compute_straight_branches()

    def _subtree_depth(self, nid: str) -> int:
        """Count max depth of subtree reachable from nid."""
        if nid in self._depth_cache:
            return self._depth_cache[nid]
        self._depth_cache[nid] = 0  # prevent infinite loops
        children = self._succ.get(nid, [])
        if not children:
            self._depth_cache[nid] = 0
            return 0
        d = 1 + max(self._subtree_depth(c) for c in children)
        self._depth_cache[nid] = d
        return d

    def _compute_straight_branches(self) -> Dict[str, str]:
        """For each condition node, decide which branch (yes/no) goes straight down.

        Returns dict: {condition_node_id: branch_that_goes_straight ("yes" or "no")}.
        The branch with deeper subtree goes straight; the shallower one detours.
        """
        # Group branch arrows by source condition
        branches: Dict[str, Dict[str, str]] = defaultdict(dict)  # {from: {branch: to}}
        for a in self._arrows:
            br = a.get("branch")
            if br in ("yes", "no"):
                branches[a["from"]][br] = a["to"]

        result: Dict[str, str] = {}
        for cond_id, br_map in branches.items():
            yes_target = br_map.get("yes")
            no_target = br_map.get("no")
            if not yes_target or not no_target:
                result[cond_id] = "yes"  # default
                continue
            yes_depth = self._subtree_depth(yes_target)
            no_depth = self._subtree_depth(no_target)
            # Deeper subtree goes straight down
            result[cond_id] = "yes" if yes_depth >= no_depth else "no"
        return result

    def route_all(self, arrows) -> List[EdgeRoute]:
        routes: List[EdgeRoute] = []
        for a in arrows:
            fp = self.spos.get(a["from"])
            tp = self.spos.get(a["to"])
            if not fp or not tp:
                continue
            br = a.get("branch")
            if br in ("yes", "no"):
                routes.append(self._route_branch(a, fp, tp, br))
            else:
                routes.append(self._route_normal(a, fp, tp))

        # Post-process: adjust label positions to avoid node overlaps
        for r in routes:
            if r.label and r.label_pos:
                r.label_pos = self._adjust_label_pos(*r.label_pos, r.label_anchor, r.label)
        return routes

    def _adjust_label_pos(self, lx, ly, anchor, text):
        """Shift label position if it overlaps any node bbox."""
        fs = FONTS["size_label"]
        tw = _px(text, fs)
        th = fs + 4
        # Compute label bbox
        if anchor == "start":
            lbox = (lx - 3, ly - th / 2, lx + tw + 3, ly + th / 2)
        elif anchor == "middle":
            lbox = (lx - tw / 2 - 3, ly - th / 2, lx + tw / 2 + 3, ly + th / 2)
        else:
            lbox = (lx - tw - 3, ly - th / 2, lx + 3, ly + th / 2)

        for pos in self.spos.values():
            # Node bbox
            nl, nt, nr, nb = pos["left"], pos["top"], pos["right"], pos["bottom"]
            # Check overlap
            if lbox[0] < nr and lbox[2] > nl and lbox[1] < nb and lbox[3] > nt:
                # Shift label above or below the node
                if ly < (nt + nb) / 2:
                    ly = nt - th / 2 - 4
                else:
                    ly = nb + th / 2 + 4
                break
        return (lx, ly)

    # ── normal arrow ─────────────────────────────────────────────────

    def _route_normal(self, arrow, fp, tp) -> EdgeRoute:
        x1, y1 = fp["cx"], fp["bottom"]
        x2, y2 = tp["cx"], tp["top"]
        lbl = arrow.get("label")

        if abs(x1 - x2) < 2:
            wps = [(x1, y1), (x1, y2)]
            lpos = (x1 + 8, (y1 + y2) / 2) if lbl else None
            anchor = "start"
        else:
            # Place horizontal segment close to whichever node is higher
            # to minimize the visible horizontal line length
            mid_y = (y1 + y2) / 2
            my = self.ta.alloc(mid_y, x1, x2)
            wps = [(x1, y1), (x1, my), (x2, my), (x2, y2)]
            lpos = ((x1 + x2) / 2, my - 10) if lbl else None
            anchor = "middle"

        return EdgeRoute(from_id=arrow["from"], to_id=arrow["to"],
                         waypoints=wps, label=lbl, label_pos=lpos,
                         label_anchor=anchor)

    # ── branch arrow ─────────────────────────────────────────────────

    def _route_branch(self, arrow, fp, tp, br) -> EdgeRoute:
        dcx = fp["cx"]
        dcy = fp["top"] + fp["h"] / 2
        x2, y2 = tp["cx"], tp["top"]
        lbl = arrow.get("label")

        fs = self.smap.get(arrow["from"], {})
        ts = self.smap.get(arrow["to"], {})
        same_lane = fs.get("participant") == ts.get("participant")

        if same_lane:
            return self._branch_same_lane(arrow, fp, tp, br, lbl, dcx, dcy, x2, y2)
        return self._branch_cross_lane(arrow, fp, tp, br, lbl, dcx, dcy, x2, y2)

    def _branch_same_lane(self, arrow, fp, tp, br, lbl, dcx, dcy, x2, y2):
        # Determine which branch goes straight down based on subtree depth
        cond_id = arrow["from"]
        straight = self._straight_branch.get(cond_id, "yes")
        is_straight = (br == straight)

        if is_straight:
            # This branch goes straight down from diamond bottom
            by = fp["bottom"]
            if abs(dcx - x2) < 2:
                wps = [(dcx, by), (dcx, y2)]
            else:
                my = self.ta.alloc(by + 15, dcx, x2)
                wps = [(dcx, by), (dcx, my), (x2, my), (x2, y2)]
            lpos = (dcx + 8, by + 12) if lbl else None
            anchor = "start"
        else:
            # Detour direction: "yes" detours RIGHT, "no" detours LEFT
            # This separates lines to opposite sides, minimizing overlaps
            use_right = (br == "yes")
            if use_right:
                ex, ry = fp["right"], dcy
                det_x = ex + 20
            else:
                ex, ry = fp["left"], dcy
                det_x = ex - 20
            # Ensure approach_y stays above target (never below)
            ideal_y = min(y2 - 15, (ry + y2) / 2)
            approach_y = self.ta.alloc(ideal_y, det_x, x2)
            if approach_y >= y2:
                approach_y = y2 - 12
            wps = [(ex, ry), (det_x, ry), (det_x, approach_y),
                   (x2, approach_y), (x2, y2)]
            if use_right:
                lpos = (ex + 8, ry - 10) if lbl else None
                anchor = "start"
            else:
                lpos = (ex - 8, ry - 10) if lbl else None
                anchor = "end"

        return EdgeRoute(from_id=arrow["from"], to_id=arrow["to"],
                         waypoints=wps, label=lbl, label_pos=lpos,
                         label_anchor=anchor, branch=br)

    def _branch_cross_lane(self, arrow, fp, tp, br, lbl, dcx, dcy, x2, y2):
        gap = L["branch_gap"]

        if x2 < dcx - 5:
            # Target left → exit left vertex
            ex, ey = fp["left"], dcy
            my = self.ta.alloc(ey, ex, x2)
            if abs(my - ey) < 2:
                wps = [(ex, ey), (x2, ey), (x2, y2)]
            else:
                wps = [(ex, ey), (ex, my), (x2, my), (x2, y2)]
            lpos = (ex - gap, ey - 10) if lbl else None
            anchor = "middle"
        elif x2 > dcx + 5:
            # Target right → exit right vertex
            ex, ey = fp["right"], dcy
            my = self.ta.alloc(ey, ex, x2)
            if abs(my - ey) < 2:
                wps = [(ex, ey), (x2, ey), (x2, y2)]
            else:
                wps = [(ex, ey), (ex, my), (x2, my), (x2, y2)]
            lpos = (ex + gap, ey - 10) if lbl else None
            anchor = "middle"
        else:
            # Same X → exit bottom
            by = fp["bottom"]
            wps = [(dcx, by), (dcx, y2)]
            lpos = (dcx + 8, by + 12) if lbl else None
            anchor = "start"

        return EdgeRoute(from_id=arrow["from"], to_id=arrow["to"],
                         waypoints=wps, label=lbl, label_pos=lpos,
                         label_anchor=anchor, branch=br)

    # ── render ───────────────────────────────────────────────────────

    @staticmethod
    def render(routes: List[EdgeRoute]) -> str:
        """Render all EdgeRoutes to SVG elements."""
        parts: List[str] = []
        for r in routes:
            if len(r.waypoints) == 2:
                (x1, y1), (x2, y2) = r.waypoints
                parts.append(_straight(x1, y1, x2, y2))
            else:
                parts.append(_pl(r.waypoints))

            if r.label and r.label_pos:
                lx, ly = r.label_pos
                parts.append(_label(lx, ly, r.label, r.label_anchor))
        return "\n".join(parts)

# ═══════════════════════════════════════════════════════════════════════
#  Main Generator
# ═══════════════════════════════════════════════════════════════════════

class FlowchartGenerator:
    def __init__(self, data):
        self.participants = data["participants"]
        self.steps = data["steps"]
        self.arrows = data["arrows"]
        self.pmap = {p["id"]: p for p in self.participants}
        self.smap = {s["id"]: s for s in self.steps}

        # ── Sugiyama pipeline ────────────────────────────────────────
        g = LayoutGraph()
        g.lane_order = [p["id"] for p in self.participants]
        for s in self.steps:
            w, h = self._sdim(s)
            g.add_node(s["id"], s["participant"], s["type"], s["text"], w, h)
        for a in self.arrows:
            g.add_edge(a["from"], a["to"], a.get("label"), a.get("branch"))

        _remove_cycles(g)
        _assign_layers(g)
        _separate_components(g)
        _align_end_nodes(g, self.steps)
        _insert_dummy_nodes(g)

        # Lane widths from node dimensions
        self._calc_lane_widths_from_layout(g)

        _minimize_crossings(g)
        self.total_h = _assign_coordinates(g, self.lane_x)

        # Build spos compatible with _shapes()
        self._build_spos(g)

        # Route edges
        router = OrthogonalRouter(self.spos, self.lane_x, self.smap, self.arrows)
        self.edge_routes = router.route_all(self.arrows)

    def _sdim(self, step):
        t = step["type"]
        if t == "condition":
            # Dynamic diamond size: inscribed rect = side/√2, so side = text_px * √2 + margin
            import math
            fs = FONTS["size_label"]
            lines = _wrap(step["text"], 20)  # generous wrap for measurement
            max_line_px = max(_px(line, fs) for line in lines)
            line_h = fs * 1.3
            text_block_h = len(lines) * line_h
            # The inscribed rectangle of a diamond with side s has w=h=s/√2
            # We need inscribed_w >= max_line_px + padding, inscribed_h >= text_block_h + padding
            pad = 16
            needed_w = (max_line_px + pad) * math.sqrt(2)
            needed_h = (text_block_h + pad) * math.sqrt(2)
            s = max(L["diamond"], needed_w, needed_h)
            return s, s
        if t in ("start", "end"):
            w = _pill_w(step["text"], FONTS["size_normal"])
            return w, L["pill_h"]
        w = _box_w(step["text"], FONTS["size_normal"])
        lines = _wrap(step["text"], L["max_vw"])
        h = max(L["box_h"], L["box_h"] + max(0, len(lines)-2) * FONTS["size_normal"] * 1.3)
        return w, h

    def _calc_lane_widths_from_layout(self, g: LayoutGraph):
        """Calculate lane widths from the Sugiyama layout graph."""
        lmw: Dict[str, float] = {}

        # Max single-node width per lane (condition nodes get extra margin for labels)
        for nid, node in g.nodes.items():
            if node["is_dummy"]:
                continue
            pid = node["participant"]
            w = node["w"]
            if node["type"] == "condition":
                w += 60  # margin for Yes/No labels + detour arrows
            lmw[pid] = max(lmw.get(pid, 0), w)

        # Account for side-by-side groups in same layer+lane
        if g.order:
            for li in g.order:
                lane_nodes: Dict[str, List[str]] = defaultdict(list)
                for nid in g.order[li]:
                    if not g.nodes[nid]["is_dummy"]:
                        lane_nodes[g.nodes[nid]["participant"]].append(nid)
                for pid, nodes in lane_nodes.items():
                    if len(nodes) >= 2:
                        total = sum(g.nodes[n]["w"] for n in nodes)
                        total += (len(nodes) - 1) * L["terminal_gap"]
                        lmw[pid] = max(lmw.get(pid, 0), total)

        self.lane_x: Dict[str, dict] = {}
        cx = L["margin_side"]
        for p in self.participants:
            bw = lmw.get(p["id"], L["min_box_w"])
            lw = max(L["min_box_w"] + 2 * L["lane_pad"], bw + 2 * L["lane_pad"])
            self.lane_x[p["id"]] = {
                "left": cx, "center": cx + lw / 2,
                "right": cx + lw, "w": lw,
            }
            cx += lw
        self.total_w = cx + L["margin_side"]

    def _build_spos(self, g: LayoutGraph):
        """Build spos dict from Sugiyama coordinates (compatible with _shapes)."""
        self.spos: Dict[str, dict] = {}
        for s in self.steps:
            sid = s["id"]
            if sid not in g.x or sid not in g.y:
                continue
            cx = g.x[sid]
            y = g.y[sid]
            w = g.nodes[sid]["w"]
            h = g.nodes[sid]["h"]
            self.spos[sid] = {
                "x": cx - w / 2, "y": y, "w": w, "h": h,
                "cx": cx, "top": y, "bottom": y + h,
                "left": cx - w / 2, "right": cx + w / 2,
            }

    # ─── SVG output ───────────────────────────────────────────────────

    def _defs(self):
        return (f'<defs>{_arrow_defs()}'
                f'<filter id="shadow" x="-10%" y="-10%" width="130%" height="130%">'
                f'<feDropShadow dx="{L["shadow_dx"]}" dy="{L["shadow_dx"]}" '
                f'stdDeviation="{L["shadow_blur"]/2}" flood-opacity="0.08"/>'
                f'</filter></defs>')

    def _bg(self):
        return f'<rect width="{self.total_w}" height="{self.total_h}" fill="{COLORS["background"]}" rx="8"/>'

    def _lanes(self):
        parts = []
        lt = L["margin_top"]
        lh = self.total_h - lt - L["margin_bot"]/2
        for p in self.participants:
            lx = self.lane_x[p["id"]]
            x, w = lx["left"], lx["w"]
            parts.append(f'<rect x="{x}" y="{lt}" width="{w}" height="{lh}" fill="{COLORS["lane_bg"]}" stroke="{COLORS["lane_border"]}"/>')
            hh = L["header_h"]
            parts.append(f'<rect x="{x}" y="{lt}" width="{w}" height="{hh}" fill="{COLORS["lane_header_bg"]}" stroke="{COLORS["lane_border"]}"/>')
            parts.append(_svg_text(lx["center"], lt+hh/2, p["name"], FONTS["size_header"],
                                   fill=COLORS["lane_header_text"], max_vw=30, bold=True))
            parts.append(_icon(p.get("icon","gear"), x+12, lt+(hh-14)/2, 14))
        return "\n".join(parts)

    def _shapes(self):
        parts = []
        for s in self.steps:
            p = self.spos[s["id"]]
            ic = self.pmap[s["participant"]].get("icon","gear")
            t = s["type"]
            if t == "condition":
                parts.append(_diamond(p["x"], p["y"], p["w"], s["text"]))
            elif t in ("start","end"):
                parts.append(_pill(p["x"], p["y"], p["w"], p["h"], s["text"]))
            else:
                parts.append(_box(p["x"], p["y"], p["w"], p["h"], s["text"], t, ic))
        return "\n".join(parts)

    def generate(self):
        return "\n".join([
            f'<svg xmlns="http://www.w3.org/2000/svg" '
            f'width="{self.total_w}" height="{self.total_h}" '
            f'viewBox="0 0 {self.total_w} {self.total_h}">',
            self._defs(), self._bg(), self._lanes(),
            self._shapes(), OrthogonalRouter.render(self.edge_routes), '</svg>'])


# ═══════════════════════════════════════════════════════════════════════
def main():
    if len(sys.argv) < 3:
        print("Usage: python3 generate_flowchart.py <input.json> <output.svg>", file=sys.stderr)
        sys.exit(1)
    with open(sys.argv[1], "r", encoding="utf-8") as f: data = json.load(f)
    svg = FlowchartGenerator(data).generate()
    with open(sys.argv[2], "w", encoding="utf-8") as f: f.write(svg)
    print(f"SVG generated: {sys.argv[2]}")

if __name__ == "__main__": main()
