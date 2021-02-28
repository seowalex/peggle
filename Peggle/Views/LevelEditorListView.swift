import SwiftUI

struct LevelEditorListView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: LevelEditorListViewModel

    let fetchLevel: (LevelRecord) throws -> Void

    @State private var alertIsPresented = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        VStack(alignment: .trailing) {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
            }
            .padding()

            if viewModel.levels.isEmpty {
                NoLevelsView()
            } else {
                LevelsView()
            }
        }
        .alert(isPresented: $alertIsPresented) {
            Alert(title: Text(alertTitle), message: Text(alertMessage))
        }
    }

    private func NoLevelsView() -> some View {
        VStack(spacing: 10) {
            Image(systemName: "xmark.bin")
                .font(.system(size: 60))
            Text("No levels found")
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .foregroundColor(.secondary)
    }

    private func LevelsView() -> some View {
        List {
            ForEach(viewModel.levels) { level in
                LevelView(level: level)
            }
            .onDelete { offsets in
                do {
                    try viewModel.deleteLevels(at: offsets)
                } catch {
                    if let title = (error as? LocalizedError)?.errorDescription,
                       let message = (error as? LocalizedError)?.recoverySuggestion {
                        alertTitle = title
                        alertMessage = message
                    } else {
                        alertTitle = "Database error"
                        alertMessage = "\(error)"
                    }

                    alertIsPresented = true
                }
            }
        }
    }

    private func LevelView(level: LevelRecord) -> some View {
        Button(action: {
            do {
                try fetchLevel(level)
                presentationMode.wrappedValue.dismiss()
            } catch {
                alertTitle = "Database error"
                alertMessage = "\(error)"
                alertIsPresented = true
            }
        }) {
            HStack {
                Text(level.name)
                    .lineLimit(1)

                if level.isProtected == true {
                    Spacer()
                    Image(systemName: "lock.fill")
                }
            }
        }
        .deleteDisabled(level.isProtected == true)
    }
}

struct LevelEditorListView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
            .sheet(isPresented: .constant(true)) {
                LevelEditorListView(
                    viewModel: LevelEditorListViewModel(database: .empty()),
                    fetchLevel: { _ in }
                )
                .accentColor(.init(red: 1, green: 0.75, blue: 0))
            }
    }
}
