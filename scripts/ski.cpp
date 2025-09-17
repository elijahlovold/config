#include <iostream>
#include <chrono>
#include <thread>

using namespace std;

void loadingBar(int width, int total) {
    cout << "\nComputing skiing probability...\n\nProgress:\n";
    for (int i = 0; i <= total; ++i) {
        float progress = static_cast<float>(i) / total;
        int barWidth = static_cast<int>(progress * width);

        cout << "[";

        for (int j = 0; j < barWidth; ++j) {
            cout << "=";
        }

        for (int j = barWidth; j < width; ++j) {
            cout << " ";
        }

        cout << "] " << static_cast<int>(progress * 100) << "%\r";
        cout.flush();

        this_thread::sleep_for(chrono::milliseconds(300));
    }

    cout << "\n\nComputation complete!\n\nResult: Yes, I am going skiing.\n\n";

}

int main() {
    int barWidth = 50;
    int totalIterations = 20;

    loadingBar(barWidth, totalIterations);

    return 0;
}
