<script setup>
import { ref } from 'vue'
import { RouterLink } from 'vue-router'
import { FileText, TrendingUp, Building2, ArrowUpRight } from 'lucide-vue-next'

const reports = ref([
  { 
    id: 'pl', 
    name: 'Profit & Loss', 
    description: 'Income statement showing revenue, expenses, and net profit',
    icon: TrendingUp,
    to: '/accounting/profit-loss',
    color: 'success'
  },
  { 
    id: 'bs', 
    name: 'Balance Sheet', 
    description: 'Statement of assets, liabilities, and equity',
    icon: Building2,
    to: '/accounting/balance-sheet',
    color: 'info'
  },
  { 
    id: 'income', 
    name: 'Income Report', 
    description: 'Detailed breakdown of all income streams',
    icon: TrendingUp,
    to: '/accounting/income-report',
    color: 'success'
  },
  { 
    id: 'expense', 
    name: 'Expense Report', 
    description: 'Detailed breakdown of all expenses',
    icon: FileText,
    to: '/accounting/expense-report',
    color: 'danger'
  }
])
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h1 class="text-2xl font-bold text-text">Financial Reports</h1>
      <p class="text-muted mt-1">Access and generate financial statements</p>
    </div>

    <!-- Reports Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <RouterLink 
        v-for="report in reports" 
        :key="report.id"
        :to="report.to"
        class="card card-hover group"
      >
        <div class="flex items-start gap-4">
          <div 
            :class="[
              'w-14 h-14 rounded-xl flex items-center justify-center transition-transform group-hover:scale-110',
              report.color === 'success' ? 'bg-success/10 text-success' : '',
              report.color === 'info' ? 'bg-info/10 text-info' : '',
              report.color === 'danger' ? 'bg-danger/10 text-danger' : ''
            ]"
          >
            <component :is="report.icon" class="w-7 h-7" />
          </div>
          <div class="flex-1">
            <h3 class="text-lg font-semibold text-text group-hover:text-primary transition-colors">
              {{ report.name }}
            </h3>
            <p class="text-sm text-muted mt-1">{{ report.description }}</p>
          </div>
          <ArrowUpRight class="w-5 h-5 text-muted group-hover:text-primary transition-colors" />
        </div>
      </RouterLink>
    </div>

    <!-- Info Card -->
    <div class="card bg-info/5 border-info/20">
      <div class="flex items-start gap-3">
        <div class="w-10 h-10 rounded-lg bg-info/10 flex items-center justify-center flex-shrink-0">
          <FileText class="w-5 h-5 text-info" />
        </div>
        <div>
          <h4 class="font-semibold text-text">About Financial Reports</h4>
          <p class="text-sm text-muted mt-1">
            Reports are derived from journal entries. All financial data is automatically calculated based on your recorded transactions.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
