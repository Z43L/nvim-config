return {
  -- name: flet-main
  s("flet-main", {
    t("import flet as ft"),
    t(""),
    t(""),
    t("def main(page: ft.Page):"),
    t("    counter = ft.Text(\"0\", size=50, data=0)"),
    t("    "),
    t(""),
    t("    page.add("),
    t("        ft.SafeArea("),
    t("            ft.Container("),
    t("                counter,"),
    t("                alignment=ft.alignment.center,"),
    t("            ),"),
    t("            expand=True,"),
    t("        )"),
    t("    )"),
    t(""),
    t(""),
    t("ft.app(main)")
  }),
}
