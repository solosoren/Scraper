#!/usr/bin/swift

import Foundation

print("Hello, World!")

var startURL: URL = URL(string: "https://fr-eu.wahoofitness.com")!
var pagesToVisit: Set<URL> = [startURL]
var visitedPages: Set<URL> = []
var sem = DispatchSemaphore(value: 0)
var round = 1

func crawl() {
    guard let pageToVisit = pagesToVisit.popFirst() else {
        print("No more pages to visit")
        sem.signal()
        return
    }
    
    if visitedPages.contains(pageToVisit) {
        crawl()
    } else {
        visit(page: pageToVisit)
    }
}

func visit(page url: URL) {
    visitedPages.insert(url)
    
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        defer { crawl() }
        guard
            let data = data,
            error == nil,
            let document = String(data: data, encoding: .utf8) else { return }
        parse(document: document, url: url)
    }
    
    task.resume()
}

func parse(document: String, url: URL) {
    
    func find() {
        let emails = findRegexMatchesIn(document)
        if emails.count > 0 {
            for email in emails {
                print("✅ Email '\(email)' found at page \(url)")
            }
        }
    }
    
    func collectLinks() -> [URL] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: document, options: [], range: NSRange(location: 0, length: document.utf16.count))
        return matches?.compactMap { $0.url } ?? []
    }
    
    find()
    if round == 1 {
       collectLinks().forEach { pagesToVisit.insert($0) }
        round = round + 1
    }
    
}

func findRegexMatchesIn(_ text: String) -> [String] {
    let pattern = "([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\\.com)"
    
    var results = [String]()
    do {
        let regex = try NSRegularExpression.init(pattern: pattern, options: .caseInsensitive)
        
        regex.enumerateMatches(in: text, options: .reportProgress, range: NSRange(location: 0, length: text.count)) { (result: NSTextCheckingResult?, _, _) in
            if result != nil {
                results.append((text as NSString).substring(with: result!.range))
            }
        }
        
    } catch let error {
        print("Internal Error: \(error.localizedDescription)")
        exit(1)
    }
    return results
}

let arg = CommandLine.arguments
crawl()
sem.wait()
print("\n")

for s in arg {
//    Inputs
    print("\n")
    print("NEXTURL----------------------")
    print(s)
    round = 1
    pagesToVisit = [URL(string: s)!]
    sem = DispatchSemaphore(value: 0)
    crawl()
    sem.wait()
}






