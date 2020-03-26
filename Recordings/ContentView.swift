//
//  ContentView.swift
//  Recordings
//
//  Created by Florian Kugler on 20-03-2020.
//  Copyright © 2020 objc.io. All rights reserved.
//

import SwiftUI

extension Item {
    var destination: some View {
        Group {
            if self is Folder {
                FolderList(folder: self as! Folder)
            } else {
                PlayerView(recording: self as! Recording)
            }
        }
    }
}

struct PlayerView: View {
    let recording: Recording
    @State private var name: String = ""
    @State private var position: TimeInterval = 0
    @ObservedObject private var player: Player // TODO create lazily
    
    init(recording: Recording) {
        self.recording = recording
        self._name = State(initialValue: recording.name)
        self.player = Player(url: recording.fileURL!)! // TODO
    }
    
    var playButtonTitle: String {
        if player.isPlaying { return "Pause" }
        else if player.isPaused { return "Resume" }
        else { return "Play" }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Name")
                TextField("Name", text: $name, onEditingChanged: { _ in
                    self.recording.setName(self.name)
                })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            HStack {
                Text(timeString(0))
                Spacer()
                Text(timeString(player.duration))
            }
            Slider(value: $player.time, in: 0...player.duration)
            Button(playButtonTitle) { self.player.togglePlay() }
                .buttonStyle(PrimaryButtonStyle())
            Spacer()
        }
        .padding()
    }
}

struct FolderList: View {
    @ObservedObject var folder: Folder
    @State var presentsNewRecording = false
    var body: some View {
        List {
            ForEach(folder.contents) { item in
                NavigationLink(destination: item.destination) {
                    Text(item.name)
                }
            }.onDelete(perform: { indices in
                let items = indices.map { self.folder.contents[$0] }
                for item in items {
                    self.folder.remove(item)
                }
            })
        }
        .navigationBarTitle("Recordings")
        .navigationBarItems(trailing: HStack {
            Button(action: {
                self.folder.add(Folder(name: "New Folder \(self.folder.contents.count)", uuid: UUID()))
            }, label: {
                Image(systemName: "folder.badge.plus")
            })
            Button(action: {
                self.presentsNewRecording = true
            }, label: {
                Image(systemName: "waveform.path.badge.plus")
            })
        })
        .sheet(isPresented: $presentsNewRecording) {
            RecordingView(folder: self.folder, isPresented: self.$presentsNewRecording)
        }
    }
}

struct RecordingView: View {
    let folder: Folder
    @Binding var isPresented: Bool
    private let recording = Recording(name: "", uuid: UUID())
    @State private var recorder: Recorder? = nil
    @State private var time: TimeInterval = 0
    
    func save() {
        recorder?.stop()
        let name: String? = "Recording \(Date())"
        if let n = name {
            recording.setName(n)
            folder.add(recording)
        } else {
            recording.deleted()
        }
        isPresented = false
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Recording")
            Text(timeString(time))
                .font(.title)
            Button("Stop") { self.save() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .onAppear {
            guard let s = self.folder.store, let url = s.fileURL(for: self.recording) else { return }
            self.recorder = Recorder(url: url) { time in
                self.time = time ?? 0
            }
        }
        .onDisappear {
            // TODO stop and delete
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color.orange))
            
    }
}

struct ContentView: View {
    let store = Store.shared
    var body: some View {
        NavigationView {
            FolderList(folder: store.rootFolder)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
