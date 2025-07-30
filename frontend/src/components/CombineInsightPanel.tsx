'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { RadialBarChart, RadialBar, Cell, ResponsiveContainer } from 'recharts';
import { CombineSpec } from '@/types/combine';

interface CombineInsightPanelProps {
  selectedCombine: CombineSpec;
  currentFieldMoisture?: number; // Current field moisture percentage
  weatherConditions?: {
    windSpeed: number;
    temperature: number;
    humidity: number;
  };
}

export function CombineInsightPanel({ 
  selectedCombine, 
  currentFieldMoisture = 14.5,
  weatherConditions = { windSpeed: 15, temperature: 22, humidity: 65 }
}: CombineInsightPanelProps) {
  const [efficiencyScore, setEfficiencyScore] = useState(0);
  const [animatedMoisture, setAnimatedMoisture] = useState(0);

  // Calculate efficiency score based on combine capabilities and current conditions
  useEffect(() => {
    let score = 75; // Base score
    
    // Adjust based on tough crop ability
    score += selectedCombine.toughCropAbility.rating * 2;
    
    // Adjust based on moisture tolerance
    const moistureInRange = currentFieldMoisture >= selectedCombine.moistureTolerance.min && 
                           currentFieldMoisture <= selectedCombine.moistureTolerance.max;
    if (moistureInRange) {
      score += 10;
    } else {
      score -= Math.abs(currentFieldMoisture - selectedCombine.moistureTolerance.optimal) * 2;
    }
    
    // Adjust based on weather conditions
    if (weatherConditions.windSpeed <= selectedCombine.harvestCapabilities.weatherLimitations.maxWindSpeed) {
      score += 5;
    } else {
      score -= 10;
    }
    
    // Cap the score between 0 and 100
    score = Math.max(0, Math.min(100, score));
    
    // Animate the score
    const timer = setTimeout(() => setEfficiencyScore(score), 500);
    return () => clearTimeout(timer);
  }, [selectedCombine, currentFieldMoisture, weatherConditions]);

  // Animate moisture gauge
  useEffect(() => {
    const timer = setTimeout(() => setAnimatedMoisture(currentFieldMoisture), 800);
    return () => clearTimeout(timer);
  }, [currentFieldMoisture]);

  // Prepare data for efficiency radial chart
  const efficiencyData = [
    {
      name: 'Efficiency',
      value: efficiencyScore,
      fill: efficiencyScore >= 80 ? '#22c55e' : efficiencyScore >= 60 ? '#f97316' : '#ef4444'
    }
  ];

  // Generate alert banners based on combine strengths and conditions
  const generateAlertBanners = () => {
    const alerts = [];

    // Moisture-based alerts
    if (currentFieldMoisture > selectedCombine.moistureTolerance.max) {
      alerts.push({
        type: 'warning',
        icon: '🌧️',
        title: 'High Moisture Alert',
        message: `Field moisture (${currentFieldMoisture}%) exceeds optimal range. Consider waiting or reducing speed.`,
        action: 'Reduce ground speed by 20%'
      });
    } else if (currentFieldMoisture < selectedCombine.moistureTolerance.min) {
      alerts.push({
        type: 'caution',
        icon: '☀️',
        title: 'Low Moisture Alert',
        message: `Field moisture (${currentFieldMoisture}%) is below optimal. Risk of grain cracking.`,
        action: 'Adjust threshing settings'
      });
    }

    // Wind-based alerts
    if (weatherConditions.windSpeed > selectedCombine.harvestCapabilities.weatherLimitations.maxWindSpeed) {
      alerts.push({
        type: 'danger',
        icon: '💨',
        title: 'High Wind Warning',
        message: `Wind speed (${weatherConditions.windSpeed} km/h) exceeds safe operating limits.`,
        action: 'Consider stopping operation'
      });
    }

    // Combine strength-based recommendations
    if (selectedCombine.toughCropAbility.rating >= 8) {
      alerts.push({
        type: 'success',
        icon: '💪',
        title: 'Tough Crop Advantage',
        message: `${selectedCombine.displayName} excels in current conditions. Maximize your productivity.`,
        action: 'Increase operating speed'
      });
    }

    return alerts;
  };

  const alertBanners = generateAlertBanners();

  // Calculate moisture gauge positioning
  const moistureRange = selectedCombine.moistureTolerance.max - selectedCombine.moistureTolerance.min;
  const currentMoisturePosition = ((animatedMoisture - selectedCombine.moistureTolerance.min) / moistureRange) * 100;
  const optimalPosition = ((selectedCombine.moistureTolerance.optimal - selectedCombine.moistureTolerance.min) / moistureRange) * 100;

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6 }}
      className="bg-white rounded-2xl shadow-field-lg overflow-hidden"
    >
      {/* Header */}
      <div className="bg-gradient-to-r from-field-green-500 to-field-green-600 px-6 py-4">
        <h2 className="text-xl font-bold text-white flex items-center gap-3">
          <div className="w-8 h-8 bg-white/20 rounded-lg flex items-center justify-center">
            <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
            </svg>
          </div>
          Combine Insights
        </h2>
      </div>

      <div className="p-6">
        {/* Efficiency Score Radial Gauge */}
        <div className="mb-8">
          <h3 className="text-lg font-semibold text-gray-900 mb-4 text-center">
            Harvest Efficiency Score
          </h3>
          <div className="relative h-48">
            <ResponsiveContainer width="100%" height="100%">
              <RadialBarChart
                cx="50%"
                cy="50%"
                innerRadius="60%"
                outerRadius="90%"
                data={efficiencyData}
                startAngle={180}
                endAngle={0}
              >
                <RadialBar
                  dataKey="value"
                  cornerRadius={20}
                  fill={efficiencyData[0].fill}
                />
              </RadialBarChart>
            </ResponsiveContainer>
            
            {/* Center score display */}
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ duration: 0.5, delay: 0.8 }}
                className="text-center"
              >
                <motion.div 
                  className={`text-4xl font-bold field-contrast-text ${
                    efficiencyScore >= 80 ? 'text-field-green-600' : 
                    efficiencyScore >= 60 ? 'text-field-orange-600' : 
                    'text-red-600'
                  } ${efficiencyScore >= 80 ? 'bounce-gentle' : ''}`}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ duration: 0.6, delay: 1.2 }}
                >
                  {Math.round(efficiencyScore)}%
                </motion.div>
                <motion.div 
                  className={`text-sm mt-2 px-3 py-1 rounded-full field-contrast-text ${
                    efficiencyScore >= 80 ? 'bg-field-green-100 text-field-green-700' : 
                    efficiencyScore >= 60 ? 'bg-field-orange-100 text-field-orange-700' : 
                    'bg-red-100 text-red-700'
                  }`}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.4, delay: 1.5 }}
                >
                  {efficiencyScore >= 80 ? '🚀 Excellent' : efficiencyScore >= 60 ? '⚡ Good' : '⚠️ Caution'}
                </motion.div>
              </motion.div>
            </div>
          </div>
        </div>

        {/* Moisture Comparison Gauge */}
        <div className="mb-8">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">
            Moisture Level Analysis
          </h3>
          
          <div className="relative">
            {/* Moisture range bar */}
            <div className="h-8 bg-gray-200 rounded-full relative overflow-hidden">
              {/* Optimal range indicator */}
              <div 
                className="absolute top-0 h-full bg-gradient-to-r from-field-green-400 to-field-green-500 rounded-full"
                style={{
                  left: '20%',
                  width: '60%'
                }}
              />
              
              {/* Current moisture indicator */}
              <motion.div
                initial={{ left: '20%' }}
                animate={{ left: `${Math.max(0, Math.min(100, currentMoisturePosition))}%` }}
                transition={{ duration: 1, delay: 0.5 }}
                className="absolute top-1 w-6 h-6 bg-field-blue-600 rounded-full border-2 border-white shadow-lg transform -translate-x-1/2"
              />
              
              {/* Optimal point indicator */}
              <div
                className="absolute top-0 w-1 h-full bg-field-green-700"
                style={{ left: `${optimalPosition}%` }}
              />
            </div>
            
            {/* Labels */}
            <div className="flex justify-between text-xs text-gray-500 mt-2">
              <span>{selectedCombine.moistureTolerance.min}%</span>
              <span className="text-field-green-600 font-semibold">
                Optimal: {selectedCombine.moistureTolerance.optimal}%
              </span>
              <span>{selectedCombine.moistureTolerance.max}%</span>
            </div>
            
            <div className="text-center mt-3">
              <span className="text-sm font-medium text-gray-700">
                Current Field Moisture: 
                <span className="text-field-blue-600 font-bold ml-1">
                  {currentFieldMoisture}%
                </span>
              </span>
            </div>
          </div>
        </div>

        {/* Alert Banners */}
        {alertBanners.length > 0 && (
          <div className="space-y-3">
            <h3 className="text-lg font-semibold text-gray-900">
              Field Conditions & Recommendations
            </h3>
            {alertBanners.map((alert, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.4, delay: index * 0.1 }}
                className={`p-4 rounded-xl border-l-4 field-touch-target-lg field-contrast-text ${
                  alert.type === 'success' 
                    ? 'bg-field-green-50 border-field-green-500'
                    : alert.type === 'warning'
                    ? 'bg-field-orange-50 border-field-orange-500 pulse-field'
                    : alert.type === 'danger'
                    ? 'bg-red-50 border-red-500 pulse-field'
                    : 'bg-field-blue-50 border-field-blue-500'
                } ${alert.type === 'danger' ? 'field-glow' : ''}`}
              >
                <div className="flex items-start gap-3">
                  <div className="text-2xl flex-shrink-0 mt-1">
                    {alert.icon}
                  </div>
                  <div className="flex-1 min-w-0">
                    <h4 className={`font-semibold text-sm ${
                      alert.type === 'success' 
                        ? 'text-field-green-800'
                        : alert.type === 'warning'
                        ? 'text-field-orange-800'
                        : alert.type === 'danger'
                        ? 'text-red-800'
                        : 'text-field-blue-800'
                    }`}>
                      {alert.title}
                    </h4>
                    <p className="text-sm text-gray-700 mt-1">
                      {alert.message}
                    </p>
                    <div className={`text-xs font-medium mt-2 px-2 py-1 rounded-full inline-block ${
                      alert.type === 'success' 
                        ? 'bg-field-green-100 text-field-green-700'
                        : alert.type === 'warning'
                        ? 'bg-field-orange-100 text-field-orange-700'
                        : alert.type === 'danger'
                        ? 'bg-red-100 text-red-700'
                        : 'bg-field-blue-100 text-field-blue-700'
                    }`}>
                      💡 {alert.action}
                    </div>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </div>
    </motion.div>
  );
}