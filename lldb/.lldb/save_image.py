#!/usr/bin/env python

import lldb
import commands
import time

def process(debugger, command, result, internal_dict):
    lldb.debugger.HandleCommand("""
    expr -l swift --
    func $process(image: UIImage) {
        let data = UIImagePNGRepresentation(image)!
        data.writeToFile("/Users/dealforest/lldb.png", atomically: true)
    }
    """.strip())
    lldb.debugger.HandleCommand('expr -l swift -- $process(' + command + ')')
    commands.getoutput("open /Users/dealforest/lldb.png")

def __lldb_init_module(debugger,internal_dict):
    debugger.HandleCommand("command script add -f save_image.process save_image")
    print "save_image command enabled."
