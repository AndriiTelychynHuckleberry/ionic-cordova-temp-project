import { Component, Input } from '@angular/core';
import { AmplitudeService } from '../amplitude.service';

@Component({
  selector: 'app-explore-container',
  templateUrl: './explore-container.component.html',
  styleUrls: ['./explore-container.component.scss'],
})
export class ExploreContainerComponent {

  @Input() name?: string;

  constructor(private amplitude: AmplitudeService) {}

  public sendEvent(): void {
    this.amplitude.track('plus_upsell_viewed');
  }

}
