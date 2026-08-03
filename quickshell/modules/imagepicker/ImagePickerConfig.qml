pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // CHANGE ME if this isn't your actual wallpaper directory - I couldn't
    // find one on this machine to confirm against.
    readonly property string directory: "/home/elovold/vids/wallpapers"

    readonly property string cacheDir: "/home/elovold/.cache/quickshell-imagepicker/thumbs"
    readonly property int thumbnailSize: 256
    // Tile size in the grid - the thumbnail is generated at thumbnailSize
    // and cropped to fill this square, so keep them close.
    readonly property int tileSize: 220

    // Both lists feed the directory nameFilters; videoExtensions also gets
    // passed to the thumbnail generator so it knows which files need an
    // ffmpeg frame-grab instead of a vipsthumbnail resize.
    readonly property var imageExtensions: ["jpg", "jpeg", "png", "webp", "bmp"]
    // readonly property var videoExtensions: ["mp4", "webm", "mkv", "mov", "m4v"]
    readonly property var videoExtensions: []

    // Called as: <applyCommand> --select <path>
    readonly property string applyCommand: "wallpaper-picker"
}
