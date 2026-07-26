#!/usr/bin/env swift
//
// Gate 1 calibration probe — CLAUDE.md §6.2a step 3.
//
// Runs the SAME Vision request the app runs (VNDetectHumanHandPoseRequest, maximumHandCount 2,
// full-resolution image — matching ImageProcessor.detectHand) over a folder of images and
// records the RAW confidence for each, not a pass/fail verdict. Thresholding happens later,
// in sweep.py, so one expensive pass supports the whole sweep.
//
//   swift Scripts/calibrate/Gate1Calibrate.swift calibration/images > calibration/gate1.csv
//
import AppKit
import Foundation
import Vision

func maxHandConfidence(at url: URL) -> Float? {
    guard
        let image = NSImage(contentsOf: url),
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    else { return nil }

    let request = VNDetectHumanHandPoseRequest()
    request.maximumHandCount = 2

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
        try handler.perform([request])
    } catch {
        FileHandle.standardError.write("vision failed for \(url.lastPathComponent): \(error)\n".data(using: .utf8)!)
        return nil
    }

    // No hand found at all is a genuine zero, not missing data.
    return (request.results ?? []).map(\.confidence).max() ?? 0
}

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    FileHandle.standardError.write("usage: swift Gate1Calibrate.swift <image-directory>\n".data(using: .utf8)!)
    exit(2)
}

let directory = URL(fileURLWithPath: arguments[1])
let extensions: Set<String> = ["jpg", "jpeg", "png", "heic"]

guard let entries = try? FileManager.default.contentsOfDirectory(
    at: directory, includingPropertiesForKeys: nil
) else {
    FileHandle.standardError.write("cannot read directory \(directory.path)\n".data(using: .utf8)!)
    exit(1)
}

let images = entries
    .filter { extensions.contains($0.pathExtension.lowercased()) }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

print("filename,gate1_confidence")
var failures = 0
for url in images {
    if let confidence = maxHandConfidence(at: url) {
        print("\(url.lastPathComponent),\(confidence)")
    } else {
        failures += 1
        print("\(url.lastPathComponent),ERROR")
    }
}

FileHandle.standardError.write(
    "gate1: scored \(images.count - failures)/\(images.count) images\n".data(using: .utf8)!
)
