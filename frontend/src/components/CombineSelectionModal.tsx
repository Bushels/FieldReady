'use client';

import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import Fuse from 'fuse.js';
import { CombineSpec } from '@/types/combine';
import { CombineCard } from './CombineCard';
import { combines } from '@/data/combines';

interface CombineSelectionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSelect: (combine: CombineSpec) => void;
}

export function CombineSelectionModal({ isOpen, onClose, onSelect }: CombineSelectionModalProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [filteredCombines, setFilteredCombines] = useState<CombineSpec[]>(combines);
  const [selectedBrand, setSelectedBrand] = useState<string | null>(null);

  // Setup Fuse.js for fuzzy search
  const fuse = new Fuse(combines, {
    keys: [
      { name: 'brand', weight: 0.3 },
      { name: 'model', weight: 0.3 },
      { name: 'displayName', weight: 0.2 },
      { name: 'bestFor', weight: 0.1 },
      { name: 'features', weight: 0.1 },
    ],
    threshold: 0.4,
    includeScore: true,
  });

  // Get unique brands for filter buttons
  const brands = Array.from(new Set(combines.map(c => c.brand)));

  // Handle search and filtering
  useEffect(() => {
    let results = combines;

    // Apply brand filter first
    if (selectedBrand) {
      results = results.filter(c => c.brand === selectedBrand);
    }

    // Apply search query
    if (searchQuery.trim()) {
      const searchResults = fuse.search(searchQuery);
      const searchedIds = new Set(searchResults.map(r => r.item.id));
      results = results.filter(c => searchedIds.has(c.id));
    }

    setFilteredCombines(results);
  }, [searchQuery, selectedBrand]);

  // Handle combine selection
  const handleSelect = useCallback((combine: CombineSpec) => {
    onSelect(combine);
    onClose();
  }, [onSelect, onClose]);

  // Handle escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [isOpen, onClose]);

  // Prevent body scroll when modal is open
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }

    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isOpen]);

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50"
            onClick={onClose}
          />

          {/* Modal */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            transition={{ type: "spring", damping: 25, stiffness: 300 }}
            className="fixed inset-0 z-50 overflow-hidden"
          >
            <div className="min-h-full flex items-center justify-center p-4">
              <div className="relative bg-white rounded-3xl shadow-2xl w-full max-w-7xl max-h-[90vh] overflow-hidden flex flex-col">
                {/* Header with search */}
                <div className="relative bg-gradient-to-r from-field-green-500 to-field-green-600 p-6 pb-4">
                  {/* Close button */}
                  <motion.button
                    whileHover={{ scale: 1.1 }}
                    whileTap={{ scale: 0.9 }}
                    onClick={onClose}
                    className="absolute top-4 right-4 p-2 bg-white/20 hover:bg-white/30 backdrop-blur-sm rounded-full transition-colors field-touch-target"
                  >
                    <svg className="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </motion.button>

                  {/* Title */}
                  <h2 className="text-3xl font-bold text-white mb-6">Select Your Combine</h2>

                  {/* Search bar */}
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                      <svg className="w-5 h-5 text-field-green-700" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                      </svg>
                    </div>
                    <input
                      type="text"
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      placeholder="Search by brand, model, or features..."
                      className="w-full pl-12 pr-4 py-4 bg-white/95 backdrop-blur-sm rounded-2xl text-gray-900 placeholder-gray-500 focus:outline-none focus:ring-4 focus:ring-white/30 transition-all text-lg field-touch-target"
                      autoFocus
                    />
                    {searchQuery && (
                      <motion.button
                        initial={{ opacity: 0, scale: 0.8 }}
                        animate={{ opacity: 1, scale: 1 }}
                        whileHover={{ scale: 1.1 }}
                        whileTap={{ scale: 0.9 }}
                        onClick={() => setSearchQuery('')}
                        className="absolute inset-y-0 right-0 pr-4 flex items-center"
                      >
                        <svg className="w-5 h-5 text-gray-400 hover:text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      </motion.button>
                    )}
                  </div>

                  {/* Brand filters */}
                  <div className="flex flex-wrap gap-2 mt-4">
                    <motion.button
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                      onClick={() => setSelectedBrand(null)}
                      className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                        !selectedBrand
                          ? 'bg-white text-field-green-600 shadow-md'
                          : 'bg-white/20 text-white hover:bg-white/30'
                      }`}
                    >
                      All Brands
                    </motion.button>
                    {brands.map((brand) => (
                      <motion.button
                        key={brand}
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                        onClick={() => setSelectedBrand(brand === selectedBrand ? null : brand)}
                        className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                          brand === selectedBrand
                            ? 'bg-white text-field-green-600 shadow-md'
                            : 'bg-white/20 text-white hover:bg-white/30'
                        }`}
                      >
                        {brand}
                      </motion.button>
                    ))}
                  </div>
                </div>

                {/* Results count */}
                <div className="px-6 py-3 bg-gray-50 border-b border-gray-200">
                  <p className="text-sm text-gray-600">
                    {filteredCombines.length} combine{filteredCombines.length !== 1 ? 's' : ''} found
                  </p>
                </div>

                {/* Combines grid */}
                <div className="flex-1 overflow-y-auto p-6">
                  <AnimatePresence mode="popLayout">
                    {filteredCombines.length > 0 ? (
                      <motion.div
                        layout
                        className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
                      >
                        {filteredCombines.map((combine, index) => (
                          <motion.div
                            key={combine.id}
                            layout
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, scale: 0.8 }}
                            transition={{ delay: index * 0.05 }}
                          >
                            <CombineCard
                              combine={combine}
                              onClick={handleSelect}
                            />
                          </motion.div>
                        ))}
                      </motion.div>
                    ) : (
                      <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        className="flex flex-col items-center justify-center py-20"
                      >
                        <svg className="w-24 h-24 text-gray-300 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2" />
                        </svg>
                        <p className="text-xl text-gray-500 font-medium">No combines found</p>
                        <p className="text-gray-400 mt-2">Try adjusting your search or filters</p>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}