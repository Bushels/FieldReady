export interface CombineSpec {
  id: string;
  brand: string;
  model: string;
  displayName: string;
  image: string;
  year?: number;
  headerSize: string;
  bestFor: string[];
  moistureTolerance: {
    min: number;
    max: number;
    optimal: number;
  };
  toughCropAbility: {
    rating: number;
    description: string;
  };
  harvestCapabilities: {
    operatingSpeedKmh: number;
    grainTankCapacityL: number;
    dailyCapacityHa: number;
    hasYieldMapping: boolean;
    hasMoistureMapping: boolean;
    weatherLimitations: {
      maxWindSpeed: number;
      maxMoisture: number;
    };
  };
  features: string[];
  advantages: string[];
}