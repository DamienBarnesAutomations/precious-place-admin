<script setup>
import { ref, onMounted } from 'vue'
import { 
  FileText, 
  PlusCircle, 
  RefreshCw, 
  Search,
  Filter,
  Loader2,
  ArrowUpRight,
  ArrowDownRight,
  ChevronLeft,
  ChevronRight
} from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const entries = ref([])
const loading = ref(false)
const error = ref(null)
const searchQuery = ref('')
const currentPage = ref(1)
const itemsPerPage = ref(10)

const JOURNAL_WEBHOOK = import.meta.env.VITE_GET_JOURNAL_ENTRIES_WEBHOOK

async function fetchEntries() {
  loading.value = true
  error.value = null
  try {
    const res = await fetch(JOURNAL_WEBHOOK)
    if (!res.ok) throw new Error('FETCH_ERROR')
    const data = await res.json()
    
    if (Array.isArray(data)) {
      entries.value = data.filter(entry => entry && Object.keys(entry).length > 0)
    } else {
      entries.value = []
    }
  } catch (err) {
    error.value = err.message
  } finally {
    loading.value = false
  }
}

onMounted(fetchEntries)

const fmt = (val) => {
  const n = Number(val)
  if (isNaN(n) || n === 0) return '—'
  return '$' + n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

const filteredEntries = () => {
  if (!searchQuery.value) return entries.value
  const query = searchQuery.value.toLowerCase()
  return entries.value.filter(entry => 
    (entry.description && entry.description.toLowerCase().includes(query)) ||
    (entry.reference && entry.reference.toString().toLowerCase().includes(query))
  )
}

const paginatedEntries = () => {
  const start = (currentPage.value - 1) * itemsPerPage.value
  return filteredEntries().slice(start, start + itemsPerPage.value)
}

const totalPages = () => Math.ceil(filteredEntries().length / itemsPerPage.value)

const refresh = () => {
  fetchEntries()
  emit('refresh')
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-text">Journal Entries</h1>
        <p class="text-muted mt-1">View and manage all journal transactions</p>
      </div>
      <div class="flex items-center gap-3">
        <button 
          @click="refresh"
          class="btn btn-outline"
        >
          <RefreshCw class="w-4 h-4" :class="{ 'animate-spin': loading }" />
          <span>Refresh</span>
        </button>
        <RouterLink to="/accounting/journal/new" class="btn btn-primary">
          <PlusCircle class="w-4 h-4" />
          <span>New Entry</span>
        </RouterLink>
      </div>
    </div>

    <!-- Filters -->
    <div class="card">
      <div class="flex flex-col sm:flex-row gap-4">
        <div class="relative flex-1">
          <Search class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted" />
          <input 
            v-model="searchQuery"
            type="text" 
            placeholder="Search transactions..."
            class="input pl-10"
          />
        </div>
        <button class="btn btn-outline">
          <Filter class="w-4 h-4" />
          <span>Filters</span>
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="card flex items-center justify-center py-20">
      <Loader2 class="w-8 h-8 text-primary animate-spin" />
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="card bg-danger/10 border-danger/30">
      <div class="flex items-center gap-3 text-danger">
        <span class="text-sm font-medium">Error: {{ error }}</span>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else-if="entries.length === 0" class="card">
      <div class="text-center py-12">
        <FileText class="w-16 h-16 text-muted mx-auto mb-4" />
        <h3 class="text-lg font-semibold text-text mb-2">No Journal Entries</h3>
        <p class="text-muted mb-6">Start by creating your first journal entry</p>
        <RouterLink to="/accounting/journal/new" class="btn btn-primary">
          <PlusCircle class="w-4 h-4" />
          <span>Create Entry</span>
        </RouterLink>
      </div>
    </div>

    <!-- Data Table -->
    <div v-else class="card p-0 overflow-hidden">
      <div class="table-container">
        <table class="table">
          <thead>
            <tr>
              <th>Date</th>
              <th>Reference</th>
              <th>Description</th>
              <th class="text-right">Debit</th>
              <th class="text-right">Credit</th>
            </tr>
          </thead>
          <tbody>
            <tr 
              v-for="entry in paginatedEntries()" 
              :key="entry.id"
              class="group"
            >
              <td class="font-mono text-sm">
                {{ new Date(entry.entry_date).toLocaleDateString('en-GB') }}
              </td>
              <td>
                <span class="badge badge-muted">#{{ entry.reference || '0000' }}</span>
              </td>
              <td class="font-medium text-text">
                {{ entry.description || 'No description' }}
              </td>
              <td class="text-right">
                <div class="flex items-center justify-end gap-2">
                  <ArrowDownRight class="w-4 h-4 text-success" />
                  <span class="font-mono text-success">{{ fmt(entry.total_debit) }}</span>
                </div>
              </td>
              <td class="text-right">
                <div class="flex items-center justify-end gap-2">
                  <ArrowUpRight class="w-4 h-4 text-danger" />
                  <span class="font-mono text-danger">{{ fmt(entry.total_credit) }}</span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination -->
      <div class="flex items-center justify-between p-4 border-t border-border">
        <p class="text-sm text-muted">
          Showing {{ (currentPage - 1) * itemsPerPage + 1 }} to {{ Math.min(currentPage * itemsPerPage, filteredEntries().length) }} of {{ filteredEntries().length }} entries
        </p>
        <div class="flex items-center gap-2">
          <button 
            @click="currentPage--"
            :disabled="currentPage === 1"
            class="btn btn-outline btn-sm"
          >
            <ChevronLeft class="w-4 h-4" />
          </button>
          <span class="px-3 py-1 text-sm font-medium text-text">
            {{ currentPage }} / {{ totalPages() }}
          </span>
          <button 
            @click="currentPage++"
            :disabled="currentPage >= totalPages()"
            class="btn btn-outline btn-sm"
          >
            <ChevronRight class="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.btn-sm {
  @apply px-2.5 py-1.5 text-sm;
}
</style>
