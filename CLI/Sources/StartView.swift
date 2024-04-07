import SwiftTUI

struct StartView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack {
                    Text("Let's start with some warm up questions!")
                        .bold()
                    Text("Right from the CLI!")
                        .bold()
                }
                .padding()
                .border()
                .background(.blue)
                Spacer()
            }
            Spacer()
        }
    }
}

