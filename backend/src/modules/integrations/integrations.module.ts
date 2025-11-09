import { Module } from '@nestjs/common';
import { IntegrationsService } from './integrations.service';
import { GoogleAdsService } from './google-ads/google-ads.service';
import { MetaAdsService } from './meta-ads/meta-ads.service';
import { LinkedinAdsService } from './linkedin-ads/linkedin-ads.service';

@Module({
  providers: [
    IntegrationsService,
    GoogleAdsService,
    MetaAdsService,
    LinkedinAdsService,
  ],
  exports: [IntegrationsService],
})
export class IntegrationsModule {}
