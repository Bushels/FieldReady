'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { CombineSelectionModal } from '@/components/CombineSelectionModal';
import { CombineInsightPanel } from '@/components/CombineInsightPanel';
import { CombineSpec } from '@/types/combine';

export default function Home() {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedCombine, setSelectedCombine] = useState<CombineSpec | null>(null);

  const handleSelectCombine = (combine: CombineSpec) => {
    setSelectedCombine(combine);
    console.log('Selected combine:', combine);
  };

  return (
    <main className="min-h-screen bg-gradient-to-br from-field-green-50 to-field-blue-50">
      {/* Header with active combine name */}
      <div className="bg-white shadow-field border-b border-gray-100">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="w-10 h-10 bg-gradient-to-br from-field-green-500 to-field-green-600 rounded-xl flex items-center justify-center">
                <svg className="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2" />
                </svg>
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">FieldReady Dashboard</h1>
                {selectedCombine && (
                  <motion.p
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    className="text-sm text-field-green-600 font-medium"
                  >
                    Active Combine: {selectedCombine.displayName}
                  </motion.p>
                )}
              </div>
            </div>
            <button
              onClick={() => setIsModalOpen(true)}
              className="px-4 py-2 bg-field-green-500 hover:bg-field-green-600 text-white font-medium rounded-xl transition-colors field-touch-target-lg field-focus field-contrast-text flex items-center gap-2 hover:shadow-field-lg"
            >
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
              </svg>
              {selectedCombine ? 'Change Combine' : 'Select Combine'}
            </button>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-4 py-8">
        {selectedCombine ? (
          // Dashboard with combine insights
          <div className="max-w-6xl mx-auto">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
              {/* Combine Insight Panel */}
              <div className="lg:col-span-2">
                <CombineInsightPanel 
                  selectedCombine={selectedCombine}
                  currentFieldMoisture={14.5}
                  weatherConditions={{
                    windSpeed: 15,
                    temperature: 22,
                    humidity: 65
                  }}
                />
              </div>
              
              {/* Selected combine details */}
              <motion.div
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                className="bg-white rounded-2xl shadow-field-lg p-6"
              >
                <h2 className="text-xl font-semibold mb-4 flex items-center gap-3">
                  <div className="w-8 h-8 bg-field-blue-100 rounded-lg flex items-center justify-center">
                    <svg className="w-5 h-5 text-field-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  Combine Specifications
                </h2>
                <div className="space-y-4">
                  <div className="flex justify-between items-center py-2 border-b border-gray-100">
                    <span className="text-sm font-medium text-gray-600">Header Size</span>
                    <span className="font-bold text-field-green-600">{selectedCombine.headerSize}</span>
                  </div>
                  <div className="flex justify-between items-center py-2 border-b border-gray-100">
                    <span className="text-sm font-medium text-gray-600">Daily Capacity</span>
                    <span className="font-bold text-field-green-600">{selectedCombine.harvestCapabilities.dailyCapacityHa} ha/day</span>
                  </div>
                  <div className="flex justify-between items-center py-2 border-b border-gray-100">
                    <span className="text-sm font-medium text-gray-600">Tough Crop Rating</span>
                    <span className="font-bold text-field-green-600">{selectedCombine.toughCropAbility.rating}/10</span>
                  </div>
                  <div className="flex justify-between items-center py-2">
                    <span className="text-sm font-medium text-gray-600">Grain Tank</span>
                    <span className="font-bold text-field-green-600">{selectedCombine.harvestCapabilities.grainTankCapacityL}L</span>
                  </div>
                </div>
              </motion.div>

              {/* Key advantages */}
              <motion.div
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.1 }}
                className="bg-white rounded-2xl shadow-field-lg p-6"
              >
                <h2 className="text-xl font-semibold mb-4 flex items-center gap-3">
                  <div className="w-8 h-8 bg-field-orange-100 rounded-lg flex items-center justify-center">
                    <svg className="w-5 h-5 text-field-orange-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  Key Advantages
                </h2>
                <div className="space-y-3">
                  {selectedCombine.advantages.map((advantage, index) => (
                    <motion.div
                      key={index}
                      initial={{ opacity: 0, x: -10 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: 0.2 + index * 0.1 }}
                      className="flex items-center gap-3 p-3 bg-field-green-50 rounded-lg"
                    >
                      <div className="w-6 h-6 bg-field-green-500 rounded-full flex items-center justify-center flex-shrink-0">
                        <svg className="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                        </svg>
                      </div>
                      <span className="text-sm font-medium text-gray-700">{advantage}</span>
                    </motion.div>
                  ))}
                </div>
              </motion.div>
            </div>
          </div>
        ) : (
          // Welcome screen when no combine is selected
          <div className="max-w-4xl mx-auto text-center">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6 }}
            >
              <h2 className="text-4xl font-bold text-gray-900 mb-4">
                Welcome to FieldReady
              </h2>
              <p className="text-xl text-gray-600 mb-8">
                Get started by selecting your combine to access intelligent harvest insights
              </p>
            </motion.div>

            {/* Open modal button */}
            <motion.button
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.2 }}
              whileHover={{ scale: 1.05, y: -2 }}
              whileTap={{ scale: 0.95 }}
              onClick={() => setIsModalOpen(true)}
              className="px-8 py-4 bg-gradient-to-r from-field-green-500 to-field-green-600 text-white font-semibold text-lg rounded-2xl shadow-field-lg hover:shadow-field-xl transition-all field-touch-target-lg field-focus field-contrast-text"
            >
              Select Your Combine
            </motion.button>
          </div>
        )}
      </div>

      {selectedCombine && (
        // Features section - only show when combine is selected
        <div className="bg-white py-16">
          <div className="container mx-auto px-4">
            <div className="max-w-6xl mx-auto">
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: 0.4 }}
                className="grid grid-cols-1 md:grid-cols-3 gap-8"
              >
                <div className="p-6 bg-gradient-to-br from-field-green-50 to-field-green-100 rounded-2xl shadow-field">
                  <div className="w-12 h-12 bg-field-green-500 rounded-xl flex items-center justify-center mb-4 mx-auto">
                    <svg className="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                  </div>
                  <h3 className="text-lg font-semibold mb-2 text-center">Real-Time Intelligence</h3>
                  <p className="text-gray-600 text-center">Live efficiency scoring and field condition analysis</p>
                </div>

                <div className="p-6 bg-gradient-to-br from-field-blue-50 to-field-blue-100 rounded-2xl shadow-field">
                  <div className="w-12 h-12 bg-field-blue-500 rounded-xl flex items-center justify-center mb-4 mx-auto">
                    <svg className="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                    </svg>
                  </div>
                  <h3 className="text-lg font-semibold mb-2 text-center">Smart Recommendations</h3>
                  <p className="text-gray-600 text-center">Actionable insights based on your combine's capabilities</p>
                </div>

                <div className="p-6 bg-gradient-to-br from-field-orange-50 to-field-orange-100 rounded-2xl shadow-field">
                  <div className="w-12 h-12 bg-field-orange-500 rounded-xl flex items-center justify-center mb-4 mx-auto">
                    <svg className="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
                    </svg>
                  </div>
                  <h3 className="text-lg font-semibold mb-2 text-center">Field-Ready Design</h3>
                  <p className="text-gray-600 text-center">Optimized for use in bright sunlight with large touch targets</p>
                </div>
              </motion.div>
            </div>
          </div>
        </div>
      )}


      {/* Combine Selection Modal */}
      <CombineSelectionModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSelect={handleSelectCombine}
      />
    </main>
  );
}