//
//  ProspectsView.swift
//  HotProspects
//
//  Created by Derya Antonelli on 16/02/2023.
//

import SwiftUI
import CodeScanner
import UserNotifications


struct ProspectsView: View {
    enum FilterType {
        case none, contacted, uncontacted
    }
    
    enum SortType {
        case none, name, mostRecent
    }
    
    @EnvironmentObject var prospects: Prospects
    
    @State private var isShowingScanner = false
    
    let filter: FilterType
    
    @State private var sortKey: SortType = .none
    
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sortedProspects) { prospect in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(prospect.name)
                                .font(.headline)
                            Text(prospect.emailAddress)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if isContacted(filterType: filter, prospect: prospect) { Image(systemName: "person.fill.badge.plus")
                                .foregroundColor(.green)
                            
                          

                    }
                        
                    }
   
                    .swipeActions {
                        if prospect.isContacted {
                            Button {
                                prospects.toggle(prospect)
                            } label: {
                                Label("Mark Uncontacted", systemImage: "person.crop.circle.badge.xmark")
                            }
                            .tint(.blue)
                        } else {
                            Button {
                                prospects.toggle(prospect)
                            } label: {
                                Label("Mark Contacted", systemImage: "person.crop.circle.fill.badge.checkmark")
                            }
                            .tint(.green)
                            Button {
                                addNotification(for: prospect)
                            } label: {
                                Label("Remind Me", systemImage: "bell")
                            }
                            .tint(.orange)
                        }
                    }
                }
                
                Button {
                    sortKey = .name
                } label: {
                    Text("Name sort")
                }
                
                Button {
                    sortKey = .mostRecent
                } label: {
                    Text("Most recent sort")
                }
                
                Button {
                    sortKey = .none
                } label: {
                    Text("Cancel sort")
                }
                
            }
            .navigationTitle(title)
            .toolbar {
                Button {
                    isShowingScanner = true
                } label: {
                    Label("Scan", systemImage: "qrcode.viewfinder")
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes: [.qr], simulatedData: "Taylor Ryson\npaul@hackingwithswift.com", completion: handleScan)
            }
        }
        
    }
    
    func isContacted(filterType: FilterType, prospect: Prospect) -> Bool {
        return filterType == .none && prospect.isContacted
    }
    
    func addNotification(for prospect: Prospect) {
        let center = UNUserNotificationCenter.current()
        
        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default
            
            var dateComponents = DateComponents()
            dateComponents.hour = 9
            //            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }
        
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                    if success {
                        addRequest()
                    } else {
                        print("D'oh")
                    }
                }
            }
        }
    }
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        
        switch result {
        case .success(let result):
            let details = result.string.components(separatedBy: "\n")
            guard details.count == 2 else { return }
            
            let person = Prospect()
            person.name = details[0]
            person.emailAddress = details[1]
            
            prospects.add(person)
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
    
    var title: String {
        switch filter {
        case .none:
            return "Everyone"
        case .contacted:
            return "Contacted people"
        case .uncontacted:
            return "Uncontacted people"
        }
    }
    
    var filteredProspects: [Prospect] {
        switch filter {
        case .none:
            return prospects.people
            
        case .contacted:
            return prospects.people.filter { $0.isContacted }
            
        case .uncontacted:
            return prospects.people.filter { !$0.isContacted }
        }
    }
    
    
    var sortedProspects: [Prospect] {
        switch sortKey {
        case .none:
            return filteredProspects
            
        case .name:
            return filteredProspects.sorted { $0.name < $1.name }
            
        case .mostRecent:
            return filteredProspects.sorted { $0.dateAdded > $1.dateAdded }
        }
    }
}

struct ProspectsView_Previews: PreviewProvider {
    static var previews: some View {
        ProspectsView(filter: .none)
    }
}
