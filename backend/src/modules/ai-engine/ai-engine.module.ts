import { Module } from '@nestjs/common';
import { AiEngineService } from './ai-engine.service';
import { BudgetOptimizerService } from './services/budget-optimizer.service';
import { CampaignGeneratorService } from './services/campaign-generator.service';
import { AdCopyGeneratorService } from './services/ad-copy-generator.service';
import { TargetingOptimizerService } from './services/targeting-optimizer.service';
import { PerformancePredictorService } from './services/performance-predictor.service';

@Module({
  providers: [
    AiEngineService,
    BudgetOptimizerService,
    CampaignGeneratorService,
    AdCopyGeneratorService,
    TargetingOptimizerService,
    PerformancePredictorService,
  ],
  exports: [AiEngineService],
})
export class AiEngineModule {}
