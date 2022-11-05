//
//  AudioRecordingViewModel.swift
//  ChatApplication
//
//  Created by hamed on 10/22/22.
//

import AVFoundation
import Foundation
import FanapPodChatSDK

protocol AudioRecordingViewModelprotocol: ObservableObject {
    var audioRecorder: AVAudioRecorder { get set }
    var startDate: Date { get set }
    var timerString: String { get set }
    var isRecording: Bool { get }
    var isPermissionGranted: Bool { get }
    var recordingFileName: String { get }
    var recordingOutputBasePath: URL? { get }
    var recordingOutputPath: URL? { get }
    func toggle()
    func start()
    func stop()
    func stopAndSend()
    func deleteFile()
    func cancel()
    func requestPermission()
}

class AudioRecordingViewModel: AudioRecordingViewModelprotocol {
    lazy var audioRecorder = AVAudioRecorder()
    var startDate: Date = .init()

    @Published
    var timerString: String = ""

    @Published
    var isRecording: Bool = false

    var isPermissionGranted: Bool { AVAudioSession.sharedInstance().recordPermission == .granted }

    var recordingFileName: String { "recording.m4a" }

    var recordingOutputBasePath: URL? { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first }

    var recordingOutputPath: URL? { recordingOutputBasePath?.appendingPathComponent(recordingFileName) }

    var threadViewModel: ThreadViewModelProtocol

    init (threadViewModel: ThreadViewModelProtocol) {
        self.threadViewModel = threadViewModel
    }

    func toggle() {
        if !isRecording {
            start()
        } else {
            stop()
        }
    }

    func start() {
        if !isPermissionGranted { requestPermission(); return }
        isRecording = true
        startDate = Date()
        threadViewModel.sendSignal(.recordVoice)
        guard let url = recordingOutputPath else { return }
        do {
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder.record()
        } catch {
            stop()
        }
    }

    func stopAndSend() {
        stop()
        if let url = recordingOutputPath {
            threadViewModel.sendFile(url, textMessage: nil)
        }
    }

    func stop() {
        isRecording = false
        audioRecorder.stop()
    }

    func cancel() {
        stop()
        deleteFile()
    }

    func deleteFile() {
        if let url = recordingOutputPath {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func requestPermission() {
        do {
            let recordingSession = AVAudioSession.sharedInstance()
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { _ in
            }
        } catch {
            print("error to get recording permission")
        }
    }
}
