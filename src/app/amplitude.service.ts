import { Injectable } from "@angular/core";

@Injectable({
    providedIn: 'root'
})
export class AmplitudeService {
    private get amplitudePlugin() {
        return (window as any)['cordova']['plugins']['AmplitudePlugin'];
    }

    public track(event_name: string, params: any = {}) {
        console.log(`[Amplitude]: Sending event ${event_name}`)

        this.amplitudePlugin.track({ prop_name: event_name, params }, (e: string) => (console.log(`[Amplitude]: ${e}`)), (e: string) => (console.error(`[Amplitude]: ${e}`)))
    }
} 