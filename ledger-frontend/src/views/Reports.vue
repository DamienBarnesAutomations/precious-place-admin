<script setup>
import { ref } from 'vue'
import { RouterLink } from 'vue-router'
import { FileText, TrendingUp, Building2, ArrowUpRight, BarChart3, PieChart, Landmark, FileLineChart, ShieldCheck } from 'lucide-vue-next'

const reports = ref([
  { 
    id: 'pl', 
    name: 'Profit & Loss', 
    description: 'Operating performance summary: revenue, COGS, and margins.',
    icon: TrendingUp,
    to: '/accounting/profit-loss',
    color: 'text-emerald-600',
    bg: 'bg-emerald-50'
  },
  { 
    id: 'bs', 
    name: 'Balance Sheet', 
    description: 'Statement of financial position: aggregate assets vs. liabilities.',
    icon: Landmark,
    to: '/accounting/balance-sheet',
    color: 'text-indigo-600',
    bg: 'bg-indigo-50'
  },
  { 
    id: 'income', 
    name: 'Income Analysis', 
    description: 'Detailed audit of all revenue realization events and categories.',
    icon: BarChart3,
    to: '/accounting/income-report',
    color: 'text-emerald-600',
    bg: 'bg-emerald-50'
  },
  { 
    id: 'expense', 
    name: 'Expense Audit', 
    description: 'Categorized breakdown of operational outflows and vendor payments.',
    icon: PieChart,
    to: '/accounting/expense-report',
    color: 'text-rose-600',
    bg: 'bg-rose-50'
  }
])
</script>

<template>
  <div class="space-y-8 pb-12 max-w-5xl mx-auto">
    <!-- Header -->
    <div class="border-b border-border pb-6">
      <h1 class="text-2xl font-bold text-text tracking-tight uppercase">Financial Statements</h1>
      <p class="text-xs font-medium text-muted mt-1 uppercase tracking-wider">Synchronized Ledger Analytics Engine</p>
    </div>

    <!-- Reports Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <RouterLink 
        v-for="report in reports" 
        :key="report.id"
        :to="report.to"
        class="group relative"
      >
        <div class="card p-6 h-full transition-all duration-200 group-hover:border-primary group-hover:shadow-md bg-white">
          <div class="flex items-start gap-5">
            <div :class="['w-12 h-12 rounded flex items-center justify-center shrink-0 border border-transparent group-hover:scale-105 transition-transform', report.bg, report.color]">
              <component :is="report.icon" class="w-6 h-6" />
            </div>
            <div class="space-y-1">
              <h3 class="text-sm font-bold text-text uppercase tracking-tight group-hover:text-primary">
                {{ report.name }}
              </h3>
              <p class="text-xs text-muted leading-relaxed">
                {{ report.description }}
              </p>
              <div class="flex items-center gap-1.5 pt-3">
                <span class="text-[10px] font-bold text-primary uppercase tracking-widest opacity-0 group-hover:opacity-100 transition-opacity">
                  Generate Statement
                </span>
                <ArrowUpRight class="w-3.5 h-3.5 text-primary opacity-0 group-hover:opacity-100 transition-opacity" />
              </div>
            </div>
          </div>
        </div>
      </RouterLink>
    </div>

    <!-- Compliance Note -->
    <div class="mt-12 bg-slate-50 border border-slate-200 rounded-lg p-6">
      <div class="flex items-start gap-4">
        <div class="w-10 h-10 bg-white rounded-full flex items-center justify-center border border-slate-200 text-slate-400">
          <ShieldCheck class="w-5 h-5" />
        </div>
        <div>
          <h4 class="text-xs font-bold text-slate-900 uppercase tracking-wider mb-1">Standard Audit Protocol</h4>
          <p class="text-[11px] text-muted leading-relaxed uppercase tracking-tight">
            All reports are derived in real-time from the immutable general ledger. Statements are generated using standard double-entry principles. Ensure all daily distributions are reconciled before final period closing.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
