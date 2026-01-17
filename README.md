# Antique Identifier App

An iOS application for identifying antiques using machine learning.

## 🚀 Features

-   **Image-based Identification:** Identify antiques by taking a photo or selecting an image from your photo library.
-   **AI-Powered Analysis:** Utilizes a CoreML model to classify images and determine if they are antiques.
-   **Detailed Information:** Provides details about the identified antique, including the estimated period and reasons for the classification.
-   **Save Your Antiques:** Save identified antiques with their images and details for future reference.

## ⚙️ How It Works

The application is designed to use a machine learning model (e.g., `AntiqueClassifier.mlmodel` for future implementation) to perform binary classification on images, determining whether the object in the image is an antique or not. Currently, it utilizes a `MobileNetV2` based model to recognize various categories of objects.

The `AntiqueClassifierService` is responsible for handling the image classification. It takes a `UIImage` as input, processes it, and passes it to the CoreML model for prediction. The service then returns a `BinaryClassificationResult` indicating whether the image is an antique and the model's confidence level.

The `AntiqueAnalyzer` service provides a more in-depth analysis of the image based on the classification result. It provides reasons for the classification and estimates the historical period of the antique.

## 🏛️ Architecture

The app follows a modern SwiftUI architecture, leveraging `MVVM (Model-View-ViewModel)` and dependency injection.

-   **Views:** The UI is built with SwiftUI. `MainView` is the primary screen, allowing users to select an image. `AntiqueDetailsScreen` displays the analysis results and allows users to save the antique.
-   **ViewModels:** `MainViewModel` and `AntiqueDetailsViewModel` contain the presentation logic for their respective views. They interact with the services to fetch and process data.
-   **Services:**
    -   `AntiqueClassifierService`: Handles the CoreML image classification.
    -   `CoreMLService`: A wrapper around the CoreML framework to provide a simpler interface for classification.
    -   `AntiqueAnalyzer`: Provides a more detailed analysis of the classification results.
-   **Models:** `Antique` and `AntiqueCategory` define the data structures for the application.
-   **Dependency Injection:** The app uses `Swinject` for dependency injection to manage the creation and resolution of services and view models. `AppAssembly` is responsible for registering all the dependencies.
-   **Data Persistence:** `SwiftData` is used to persist the identified antiques on the device.

## 🏁 Getting Started

To run the app on your device or simulator:

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/Antique-Identifier-App.git
    ```
2.  **Open the project in Xcode:**
    ```bash
    open Antique-Identifier-App/Antique-Identifier-App.xcodeproj
    ```
3.  **Build and run:**
    -   Select your target device or simulator.
    -   Click the "Run" button or press `Cmd+R`.

## 📦 Dependencies

-   [Swinject](https://github.com/Swinject/Swinject): A lightweight dependency injection framework for Swift.
-   [SwiftData](https://developer.apple.com/xcode/swiftdata/): Apple's framework for data persistence.
