import SwiftUI
import MapKit

struct RecordMapView: View {
    let record: PortalRecord
    @State private var region: MKCoordinateRegion
    
    init(record: PortalRecord) {
        self.record = record
        let coordinate = CLLocationCoordinate2D(
            latitude: record.latitude,
            longitude: record.longitude
        )
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [record]) { record in
            MapMarker(
                coordinate: CLLocationCoordinate2D(
                    latitude: record.latitude,
                    longitude: record.longitude
                ),
                tint: .blue
            )
        }
        .frame(height: 200)
        .cornerRadius(12)
        .padding()
    }
} 