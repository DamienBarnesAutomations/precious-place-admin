<script setup>
import { ref } from 'vue'
import { RouterLink } from 'vue-router'
import { FileText, TrendingUp, Building2, ArrowUpRight, BarChart3, PieChart, Landmark, FileLineChart } from 'lucide-vue-next'

const reports = ref([
  { 
    id: 'pl', 
    name: 'Profit & Loss', 
    description: 'Statement of comprehensive income and operational margins.',
    icon: TrendingUp,
    to: '/accounting/profit-loss',
    color: 'text-success',
    bg: 'bg-success/10'
  },
  { 
    id: 'bs', 
    name: 'Balance Sheet', 
    description: 'Statement of financial position: assets, liabilities, and equity.',
    icon: Landmark,
    to: '/accounting/balance-sheet',
    color: 'text-info',
    bg: 'bg-info/10'
  },
  { 
    id: 'income', 
    name: 'Income Analysis', 
    description: 'Detailed audit of revenue streams and realization timestamps.',
    icon: BarChart3,
    to: '/accounting/income-report',
    color: 'text-success',
    bg: 'bg-success/10'
  },
  { 
    id: 'expense', 
    name: 'Expense Audit', 
    description: 'Breakdown of operational outflow and vendor distributions.',
    icon: PieChart,
    to: '/accounting/expense-report',
    color: 'text-danger',
    bg: 'bg-danger/10'
  }
])
</script>

<template>
  <div class="space-y-8 animate-fade-in pb-12">
    <!-- Header -->
    <div class="border-b border-border pb-6">
      <div class="flex items-center gap-2 mb-1">
        <FileLineChart class="w-4 h-4 text-primary" />
        <span class="text-[10px] font-black text-muted uppercase tracking-[0.2em]">Analytical Engine</span>
      </div>
      <h1 class="text-3xl font-black text-text tracking-tighter uppercase">Financial Reporting</h1>
      <p class="text-[11px] text-muted-dark font-bold uppercase tracking-widest mt-1">Generate verified statements derived from synchronized ledger distributions.</p>
    </div>

    <!-- Reports Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <RouterLink 
        v-for="report in reports" 
        :key="report.id"
        :to="report.to"
        class="card group hover:border-primary/30 transition-all duration-300 relative overflow-hidden"
      >
        <!-- Background Decoration -->
        <div class="absolute -right-4 -bottom-4 opacity-5 rotate-12 transition-transform group-hover:scale-110 duration-500">
          <component :is="report.icon" class="w-32 h-32" />
        </div>

        <div class="flex items-start gap-6 relative z-10">
          <div 
            :class="[
              'w-14 h-14 rounded bg-background border border-border flex items-center justify-center transition-all duration-300 group-hover:shadow-glow-primary',
              report.bg
            ]"
          >
            <component :is="report.icon" :class="['w-7 h-7', report.color]" />
          </div>
          <div class="flex-1">
            <h3 class="text-sm font-black text-text uppercase tracking-widest group-hover:text-primary transition-colors">
              {{ report.name }}
            </h3>
            <p class="text-[11px] text-muted-dark font-bold uppercase tracking-tight mt-1 leading-relaxed">
              {{ report.description }}
            </p>
            <div class="flex items-center gap-2 mt-4">
              <span class="text-[9px] font-black text-primary uppercase tracking-[0.2em]">Generate Statement</span>
              <ArrowUpRight class="w-3 h-3 text-primary" />
            </div>
          </div>
        </div>
      </RouterLink>
    </div>

    <!-- Info Card / Audit Note -->
    <div class="card bg-background/30 border-dashed p-8">
      <div class="flex items-start gap-6">
        <div class="w-12 h-12 rounded-full bg-primary/5 border border-primary/10 flex items-center justify-center flex-shrink-0">
          <FileText class="w-6 h-6 text-primary/40" />
        </div>
        <div>
          <h4 class="text-[11px] font-black text-text uppercase tracking-[0.2em] mb-2">Internal Audit Protocol</h4>
          <p class="text-[11px] text-muted-dark font-bold uppercase tracking-tighter leading-relaxed max-w-2xl">
            All statements are dynamically computed from reconciled journal entries. Reports reflect the current real-time state of the general ledger. For official fiscal filings, please perform a final reconciliation of all pending distributions.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.animate-fade-in {
  animation: fadeIn 0.5s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
</style>
