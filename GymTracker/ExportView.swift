//
//  ExportView.swift
//  GymTracker
//
//  Created by almog lachiany on 23/09/2025.
//

import SwiftUI
import SwiftData
import WebKit

struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedMonth = Date()
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showingPreview = false
    @State private var exportHTML = ""
    
    private let exportManager: ExportManager
    
    init() {
        // We'll initialize this properly in the view
        self.exportManager = ExportManager(modelContext: ModelContext(try! ModelContainer(for: WorkoutSession.self)))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "tablecells")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("ייצוא דוח חודשי")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("יצירת טבלה מפורטת של האימונים החודשיים")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Month Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("בחר חודש")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    DatePicker("חודש", selection: $selectedMonth, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                .padding(.horizontal)
                
                // Preview Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("תצוגה מקדימה")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        generatePreview()
                    }) {
                        HStack {
                            Image(systemName: "eye")
                            Text("הצג תצוגה מקדימה")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Export Actions
                VStack(spacing: 12) {
                    Button(action: {
                        exportAndShare()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("ייצא ושתף")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        saveToFiles()
                    }) {
                        HStack {
                            Image(systemName: "folder")
                            Text("שמור לקובץ")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("הוראות")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• הדוח כולל את כל האימונים מהחודש הנבחר")
                        Text("• הטבלה כוללת את המשקלים הטובים ביותר לכל תרגיל")
                        Text("• ניתן למלא את משקל הבוקר ידנית בטבלה")
                        Text("• הקובץ נשמר בפורמט HTML וניתן לפתיחה בדפדפן")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("ייצוא")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: shareItems)
            }
            .sheet(isPresented: $showingPreview) {
                PreviewSheet(html: exportHTML)
            }
        }
        .onAppear {
            // Initialize export manager with proper context
            let _ = ExportManager(modelContext: modelContext)
        }
    }
    
    private func generatePreview() {
        let manager = ExportManager(modelContext: modelContext)
        exportHTML = manager.generateMonthlyExport(for: selectedMonth)
        showingPreview = true
    }
    
    private func exportAndShare() {
        let manager = ExportManager(modelContext: modelContext)
        shareItems = manager.shareExport(for: selectedMonth)
        showingShareSheet = true
    }
    
    private func saveToFiles() {
        let manager = ExportManager(modelContext: modelContext)
        if let fileURL = manager.exportToFile(for: selectedMonth) {
            shareItems = [fileURL]
            showingShareSheet = true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PreviewSheet: View {
    let html: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            WebView(html: html)
                .navigationTitle("תצוגה מקדימה")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("סגור") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct WebView: UIViewRepresentable {
    let html: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(html, baseURL: nil)
    }
}

#Preview {
    ExportView()
        .modelContainer(for: [WorkoutSession.self, ExerciseSession.self, SetLog.self])
}
