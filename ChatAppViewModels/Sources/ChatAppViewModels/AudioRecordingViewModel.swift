//
//  AudioRecordingViewModel.swift
//  ChatApplication
//
//  Created by hamed on 10/22/22.
//

import AVFoundation
import Chat
import Foundation
import OSLog

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

public final class AudioRecordingViewModel: AudioRecordingViewModelprotocol {
    public lazy var audioRecorder = AVAudioRecorder()
    public var startDate: Date = .init()
    @Published public var timerString: String = ""
    @Published public var isRecording: Bool = false
    private var timer: Timer?
    public var isPermissionGranted: Bool { AVAudioSession.sharedInstance().recordPermission == .granted }
    public var recordingFileName: String { "recording.m4a" }
    public var recordingOutputBasePath: URL? { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first }
    public var recordingOutputPath: URL? { recordingOutputBasePath?.appendingPathComponent(recordingFileName) }
    public weak var threadViewModel: ThreadViewModel?

    public init(){}

    public func toggle() {
        if !isRecording {
            start()
        } else {
            stop()
        }
    }

    public func start() {
        if !isPermissionGranted { requestPermission(); return }
        isRecording = true
        startDate = Date()
        threadViewModel?.sendSignal(.recordVoice)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.timerString = self.startDate.distance(to: Date()).timerString ?? ""
        }
        guard let url = recordingOutputPath else { return }
        do {
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            ]
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder.record()
        } catch {
            stop()
        }
    }

    public func stopAndSend() {
        stop()
        if let url = recordingOutputPath {
            threadViewModel?.sendFiles([url], messageType: .voice)
        }
    }

    public func stop() {
        isRecording = false
        audioRecorder.stop()
        timer?.invalidate()
    }

    public func cancel() {
        stop()
        deleteFile()
    }

    public func deleteFile() {
        if let url = recordingOutputPath {
            try? FileManager.default.removeItem(at: url)
        }
    }

    public func requestPermission() {
        do {
            let recordingSession = AVAudioSession.sharedInstance()
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission { _ in
            }
        } catch {
            Logger.viewModels.info("error to get recording permission")
        }
    }
}
