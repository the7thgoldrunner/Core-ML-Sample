# Car Recognizer (based on Core-ML-Sample project)

![](coreml.gif)

## Description

This is a test project for a University course, with the goal of detecting motor vehicles (cars) on the rear camera and placing a bounding box on top of them.

Unfortunately, the CoreML seems a bit limited as of the iOS 11 release, since objects can be tracked, but they can't be detected directly by the API, only faces, text and rectangles can. This has lead us to simply detect the presence of cars, but we weren't able to accurately set a bounding box over said detected vehicles.

## Requirements

As of this writing, this demo relies on the un-released iOS 11 Operating System and Xcode 9 IDEs, using both the CoreML framework, Swift 4, and the Inceptionv3 neural network classifier.

## Special Thanks

Thanks to [iOS-10-Sampler](https://github.com/shu223/iOS-10-Sampler).
