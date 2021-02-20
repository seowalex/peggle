import SwiftUI

struct LevelEditorListView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: LevelEditorListViewModel
    @Binding var level: Level

    let fetchLevel: () throws -> Void

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
                EmptyLevelsList()
            } else {
                LevelsList()
            }
        }
        .alert(isPresented: $alertIsPresented) {
            Alert(title: Text(alertTitle), message: Text(alertMessage))
        }
    }

    private func EmptyLevelsList() -> some View {
        VStack(spacing: 10) {
            Image(systemName: "xmark.bin")
                .font(.system(size: 60))
            Text("No levels found")
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .foregroundColor(.secondary)
    }

    private func LevelsList() -> some View {
        List {
            ForEach(viewModel.levels) { level in
                Button(action: {
                    do {
                        self.level = level
                        try fetchLevel()
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        alertTitle = "Database error"
                        alertMessage = "\(error)"
                        alertIsPresented = true
                    }
                }) {
                    Text(level.name)
                        .lineLimit(1)
                }
            }
            .onDelete { offsets in
                do {
                    try viewModel.deleteLevels(at: offsets)
                } catch {
                    alertTitle = "Database error"
                    alertMessage = "\(error)"
                    alertIsPresented = true
                }
            }
        }
    }
}

struct LevelEditorListView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
            .sheet(isPresented: .constant(true)) {
                LevelEditorListView(
                    viewModel: LevelEditorListViewModel(database: .empty()),
                    level: .constant(Level(name: "")),
                    fetchLevel: {}
                )
            }
    }
}
