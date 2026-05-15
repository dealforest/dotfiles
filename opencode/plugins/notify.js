export const NotifyPlugin = async ({ $ }) => {
  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        await $`bash "$HOME/.config/opencode/scripts/notify.sh" "タスク完了" "Pop"`
      } else if (event.type === "permission.asked") {
        const permission = (event.properties?.permission || "操作").replace(/[\$`\\]/g, "")
        await $`bash "$HOME/.config/opencode/scripts/notify.sh" "${permission} の承認が必要です" "Blow"`
      }
    },
  }
}
