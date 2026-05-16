#include <QtQuickTest>
#include <QtPlugin>
#include <QGuiApplication>

Q_IMPORT_PLUGIN(QuickPreviewPlugin)

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName("QuickPreview");
    app.setOrganizationDomain("net.veskuh.test");

    return quick_test_main(argc, argv, "quickpreview", QUICK_TEST_SOURCE_DIR);
}
