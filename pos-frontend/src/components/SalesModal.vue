<script setup>
import { 
  X, 
  TrendingUp, 
  ChevronDown 
} from 'lucide-vue-next'
import { usePosStore } from '../stores/posStore'

const store = usePosStore()
</script>

<template>
  <div v-if="store.showSalesModal" class="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/95 backdrop-blur-2xl">
    <div class="bg-surface border border-border w-full max-w-3xl flex flex-col max-h-[90vh] shadow-[0_0_80px_rgba(0,0,0,0.6)] overflow-hidden rounded-none">
      
      <!-- Summary Bar -->
      <div class="p-8 border-b border-border flex justify-between items-center bg-bg/40 relative overflow-hidden">
        <div class="absolute inset-0 opacity-5 pointer-events-none">
          <div class="absolute inset-0" style="background-image: radial-gradient(var(--color-primary) 1px, transparent 1px); background-size: 20px 20px;"></div>
        </div>
        
        <div class="flex items-center gap-6 relative z-10">
          <div class="w-14 h-14 bg-primary/10 flex items-center justify-center border border-primary/20">
            <TrendingUp class="w-8 h-8 text-primary" />
          </div>
          <div>
            <h2 class="text-xs font-black uppercase tracking-[0.4em]">Daily Sales Activity</h2>
            <div class="flex items-center gap-3 mt-1.5">
              <span class="text-[10px] font-bold text-muted uppercase tracking-[0.2em] italic">Station: 01</span>
              <span class="w-1 h-1 bg-border rounded-full"></span>
              <span class="text-[10px] font-bold text-muted uppercase tracking-[0.2em] italic">{{ new Date().toLocaleDateString('en-GB') }}</span>
            </div>
          </div>
        </div>

        <div class="text-right hidden sm:block">
          <p class="text-muted text-[9px] font-black uppercase tracking-[0.4em] leading-none mb-1 opacity-60">Revenue Today</p>
          <p class="text-4xl font-black text-primary font-mono tracking-tighter leading-none">{{ store.currency }}{{ store.dayTotal.toFixed(2) }}</p>
        </div>

        <button @click="store.showSalesModal = false" class="h-12 w-12 flex items-center justify-center hover:bg-white/5 transition-colors text-muted hover:text-white">
          <X class="w-6 h-6" />
        </button>
      </div>
      
      <!-- Receipt List -->
      <div class="flex-1 overflow-y-auto p-8 space-y-8 custom-scrollbar bg-bg/10">
        <div v-if="!store.groupedSales || store.groupedSales.length === 0" class="py-32 flex flex-col items-center justify-center text-muted border border-dashed border-border">
          <TrendingUp class="w-16 h-16 mb-6 opacity-5" />
          <p class="text-[11px] font-black uppercase tracking-[0.4em]">Zero Transactions Recorded</p>
        </div>

        <!-- Single Receipt Aesthetic -->
        <div v-for="group in store.groupedSales" :key="group.id" class="relative">
          <div 
            @click="store.toggleTransaction(group.id)" 
            class="p-6 bg-surface border border-border hover:border-primary/40 transition-all group cursor-pointer"
          >
            <div class="flex justify-between items-center">
              <div class="flex items-center gap-8">
                <div class="flex flex-col">
                  <span class="text-[9px] font-black text-muted uppercase tracking-[0.3em] mb-1">Time</span>
                  <span class="font-mono text-xs font-black text-text-secondary leading-none">
                    {{ new Date(group.time).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit', second: '2-digit'}) }}
                  </span>
                </div>
                <div class="flex flex-col">
                  <span class="text-[9px] font-black text-muted uppercase tracking-[0.3em] mb-1">Transaction</span>
                  <span class="text-xs font-black text-text-secondary tracking-widest leading-none">#{{ group.id.toString().padStart(6, '0') }}</span>
                </div>
              </div>
              <div class="flex items-center gap-8">
                <div class="text-right">
                  <span class="text-[9px] font-black text-muted uppercase tracking-[0.3em] mb-1 block">Amount</span>
                  <span class="font-black text-primary font-mono text-2xl tracking-tighter leading-none">{{ store.currency }}{{ group.total.toFixed(2) }}</span>
                </div>
                <ChevronDown 
                  class="w-5 h-5 text-muted transition-transform duration-500" 
                  :class="{'rotate-180 text-primary': store.expandedTransactions?.includes(group.id)}" 
                />
              </div>
            </div>

            <!-- Receipt Detail (Dotted Style) -->
            <div v-if="store.expandedTransactions?.includes(group.id)" class="mt-8 pt-8 border-t border-dashed border-border space-y-4 animate-scale-in">
              <div class="space-y-3 font-mono">
                <div v-for="item in group.items" :key="item.id" class="flex justify-between items-start text-[11px] uppercase">
                  <div class="flex gap-4">
                    <span class="text-primary opacity-60">{{ item.quantity.toString().padStart(2, '0') }}</span>
                    <span class="text-text-secondary">{{ item.name }}</span>
                  </div>
                  <span class="text-text-muted">{{ Number(item.total_price).toFixed(2) }}</span>
                </div>
              </div>
              <div class="pt-4 border-t border-dotted border-border flex justify-between items-center text-[10px] font-black uppercase tracking-widest text-muted">
                <span>Total Items: {{ group.items.reduce((acc, i) => acc + i.quantity, 0) }}</span>
                <span>Payment: CASH/TERMINAL</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Footer Action -->
      <div class="p-8 border-t border-border bg-bg flex justify-end items-center shrink-0">
        <button 
          @click="store.showSalesModal = false" 
          class="btn-base h-14 px-12 bg-surface hover:bg-surface-elevated border border-border text-text transition-all shadow-2xl"
        >
          Close Log
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.animate-scale-in {
  animation: scaleIn 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes scaleIn {
  from { opacity: 0; transform: scale(0.98); }
  to { opacity: 1; transform: scale(1); }
}
</style>
