'use client';

import { motion } from 'framer-motion';
import { CombineSpec } from '@/types/combine';

interface CombineCardProps {
  combine: CombineSpec;
  onClick: (combine: CombineSpec) => void;
}

export function CombineCard({ combine, onClick }: CombineCardProps) {
  const toughCropColor = combine.toughCropAbility.rating >= 8 
    ? 'text-field-green-600' 
    : combine.toughCropAbility.rating >= 6 
    ? 'text-field-orange-600' 
    : 'text-gray-600';

  const moistureToleranceWidth = ((combine.moistureTolerance.max - combine.moistureTolerance.min) / 10) * 100;

  return (
    <motion.div
      whileHover={{ scale: 1.02, y: -4 }}
      whileTap={{ scale: 0.98 }}
      transition={{ type: "spring", stiffness: 300, damping: 20 }}
      onClick={() => onClick(combine)}
      className="relative bg-white rounded-2xl shadow-field-lg hover:shadow-field-xl transition-shadow cursor-pointer overflow-hidden group"
    >
      {/* Gradient overlay for visual appeal */}
      <div className="absolute inset-0 bg-gradient-to-br from-field-green-500/5 to-field-blue-500/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
      
      {/* Card content */}
      <div className="relative p-6">
        {/* Header with combine image */}
        <div className="relative h-48 mb-6 bg-gradient-to-br from-gray-100 to-gray-200 rounded-xl overflow-hidden">
          <div className="absolute inset-0 flex items-center justify-center">
            {/* Placeholder for combine image */}
            <div className="text-gray-400">
              <svg className="w-32 h-32" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2" />
              </svg>
            </div>
          </div>
          
          {/* Brand badge */}
          <div className="absolute top-3 left-3">
            <div className="px-3 py-1 bg-white/90 backdrop-blur-sm rounded-full text-xs font-semibold text-gray-700 shadow-sm">
              {combine.brand}
            </div>
          </div>
        </div>

        {/* Combine name and model */}
        <h3 className="text-xl font-bold text-gray-900 mb-1">
          {combine.model}
        </h3>
        <p className="text-sm text-gray-500 mb-4">{combine.year} Model</p>

        {/* Key specs with visual indicators */}
        <div className="space-y-4">
          {/* Header size */}
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-gray-600">Header Size</span>
            <span className="text-sm font-bold text-gray-900">{combine.headerSize}</span>
          </div>

          {/* Best for crops */}
          <div>
            <span className="text-sm font-medium text-gray-600 block mb-2">Best For</span>
            <div className="flex flex-wrap gap-2">
              {combine.bestFor.slice(0, 3).map((crop) => (
                <span
                  key={crop}
                  className="px-2 py-1 bg-field-green-100 text-field-green-700 rounded-full text-xs font-medium"
                >
                  {crop}
                </span>
              ))}
              {combine.bestFor.length > 3 && (
                <span className="px-2 py-1 bg-gray-100 text-gray-600 rounded-full text-xs font-medium">
                  +{combine.bestFor.length - 3}
                </span>
              )}
            </div>
          </div>

          {/* Tough crop ability with visual rating */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium text-gray-600">Tough Crop Ability</span>
              <span className={`text-sm font-bold ${toughCropColor}`}>
                {combine.toughCropAbility.rating}/10
              </span>
            </div>
            <div className="relative h-2 bg-gray-200 rounded-full overflow-hidden">
              <motion.div
                initial={{ width: 0 }}
                animate={{ width: `${combine.toughCropAbility.rating * 10}%` }}
                transition={{ duration: 0.8, delay: 0.2 }}
                className={`absolute inset-y-0 left-0 rounded-full ${
                  combine.toughCropAbility.rating >= 8 
                    ? 'gradient-field-green' 
                    : combine.toughCropAbility.rating >= 6 
                    ? 'gradient-field-orange' 
                    : 'bg-gray-400'
                }`}
              />
            </div>
            <p className="text-xs text-gray-500 mt-1">{combine.toughCropAbility.description}</p>
          </div>

          {/* Moisture tolerance range */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium text-gray-600">Moisture Range</span>
              <span className="text-sm font-bold text-gray-900">
                {combine.moistureTolerance.min}-{combine.moistureTolerance.max}%
              </span>
            </div>
            <div className="relative h-2 bg-gray-200 rounded-full">
              <motion.div
                initial={{ width: 0 }}
                animate={{ width: `${moistureToleranceWidth}%` }}
                transition={{ duration: 0.8, delay: 0.3 }}
                className="absolute inset-y-0 left-0 gradient-field-blue rounded-full"
                style={{ marginLeft: `${(combine.moistureTolerance.min / 30) * 100}%` }}
              />
            </div>
          </div>

          {/* Daily capacity */}
          <div className="pt-3 border-t border-gray-100">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-gray-600">Daily Capacity</span>
              <span className="text-lg font-bold text-field-green-600">
                {combine.harvestCapabilities.dailyCapacityHa} ha/day
              </span>
            </div>
          </div>
        </div>

        {/* Feature badges */}
        <div className="mt-4 flex gap-2">
          {combine.harvestCapabilities.hasYieldMapping && (
            <div className="p-1.5 bg-field-blue-100 rounded-lg" title="Yield Mapping">
              <svg className="w-4 h-4 text-field-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
              </svg>
            </div>
          )}
          {combine.harvestCapabilities.hasMoistureMapping && (
            <div className="p-1.5 bg-field-blue-100 rounded-lg" title="Moisture Mapping">
              <svg className="w-4 h-4 text-field-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z" />
              </svg>
            </div>
          )}
        </div>
      </div>

      {/* Hover indicator */}
      <motion.div
        initial={{ opacity: 0 }}
        whileHover={{ opacity: 1 }}
        className="absolute bottom-0 left-0 right-0 h-1 gradient-field-green"
      />
    </motion.div>
  );
}