//
//  Prospect.swift
//  HotProspects
//
//  Created by Derya Antonelli on 20/02/2023.
//

import Foundation

class Prospect: Identifiable, Codable {
    var id = UUID()
    var name = "Anonymous"
    var emailAddress = ""
    fileprivate(set) var isContacted = false
    private(set) var dateAdded: Date = Date.now
}


@MainActor class Prospects: ObservableObject {
    @Published private(set) var people: [Prospect]
    let saveKey = "SavedData"
    
    private let savePath = FileManager.documentsDirectory.appendingPathExtension("prospects.txt")
    
    init() {
        do {
            let data = try Data(contentsOf: savePath)
            self.people = try JSONDecoder().decode([Prospect].self, from: data)
        } catch {
            self.people = []
        }
        
    }
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(people)
            try data.write(to: savePath, options: [.atomic, .completeFileProtection])
        } catch {
            print("\(error)")
        }
    }
    
    func add(_ prospect: Prospect) {
        people.append(prospect)
        save()
    }
    
    func toggle(_ prospect: Prospect) {
        objectWillChange.send()
        prospect.isContacted.toggle()
        save()
    }
}
