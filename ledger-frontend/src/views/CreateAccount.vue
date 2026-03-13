<script setup>
import { ref, watch, onMounted, computed } from 'vue'
import { Users, RefreshCw, Loader2, CheckCircle, ShieldPlus, ArrowRight } from 'lucide-vue-next'

const emit = defineEmits(['refresh'])

const loading = ref(false)
const fetchingMetadata = ref(false)
const isSuccess = ref(false)

// Form State
const code = ref('')
const name = ref('')
const type = ref('asset')
const categoryId = ref(null)
const normalBalance = ref('debit')

// Metadata from DB
const allCategories = ref([])

const fetchMetadata = async () => {
  fetchingMetadata.value = true
  try {
    const res = await fetch(import.meta.env.VITE_GET_CATEGORIES_WEBHOOK)
    const data = await res.json()
    allCategories.value = Array.isArray(data) ? data : []
    setInitialCategory()
  } catch (err) {
    console.error('Failed to load categories:', err)
  } finally {
    fetchingMetadata.value = false
  }
}

const filteredCategories = computed(() => {
  return allCategories.value.filter(cat => cat.type === type.value)
})

const setInitialCategory = () => {
  if (filteredCategories.value.length > 0) {
    categoryId.value = filteredCategories.value[0].id
  }
}

watch(type, (newType) => {
  normalBalance.value = ['asset', 'expense'].includes(newType) ? 'debit' : 'credit'
  setInitialCategory()
})

onMounted(fetchMetadata)

const submitAccount = async () => {
  if (!code.value || !name.value || !categoryId.value) return
  
  loading.value = true
  const payload = {
    code: code.value.trim(),
    name: name.value.trim(),
    type: type.value,
    category_id: categoryId.value,
    normal_balance: normalBalance.value
  }

  try {
    const res = await fetch(import.meta.env.VITE_CREATE_ACCOUNT_WEBHOOK, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })

    if (!res.ok) throw new Error('DATA_INITIALIZATION_ERROR')

    isSuccess.value = true
    code.value = ''
    name.value = ''
    
    setTimeout(() => { isSuccess.value = false }, 4000)
    emit('refresh')
  } catch (err) {
    alert('Failed to register new account in chart of accounts.')
  } finally {
    loading.value = false
  }
}

const refresh = () => {
  fetchMetadata()
  emit('refresh')
}
</script>

<template>
  <div class="space-y-6 max-w-4xl mx-auto pb-12">
    <!-- Header -->
    <div class="flex items-end justify-between border-b border-border pb-5">
      <div>
        <h1 class="text-xl font-bold text-text tracking-tight uppercase">Chart of Accounts</h1>
        <div class="flex items-center gap-2 mt-1">
          <ShieldPlus class="w-3.5 h-3.5 text-primary" />
          <p class="text-[11px] font-medium text-muted uppercase tracking-wider">Account Initialization</p>
        </div>
      </div>
      
      <button @click="refresh" class="btn btn-outline h-9">
        <RefreshCw class="w-3.5 h-3.5" :class="{ 'animate-spin': fetchingMetadata }" />
        <span class="ml-1">Sync Meta</span>
      </button>
    </div>

    <!-- Success Feedback -->
    <Transition name="fade">
      <div v-if="isSuccess" class="bg-emerald-50 border border-emerald-200 p-4 rounded-lg flex items-center gap-3">
        <CheckCircle class="w-5 h-5 text-emerald-600" />
        <p class="text-xs font-bold text-emerald-800 uppercase tracking-tight">Account successfully registered in master hierarchy.</p>
      </div>
    </Transition>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <!-- Main Form -->
      <div class="lg:col-span-2 space-y-6">
        <div class="card p-6 bg-white space-y-6">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="space-y-1.5">
              <label class="text-[10px] font-bold text-muted-dark uppercase tracking-widest">Account Code</label>
              <input v-model="code" type="text" placeholder="1000" class="input input-mono uppercase" />
            </div>
            <div class="space-y-1.5">
              <label class="text-[10px] font-bold text-muted-dark uppercase tracking-widest">Account Name</label>
              <input v-model="name" type="text" placeholder="e.g. Cash at Bank" class="input" />
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="space-y-1.5">
              <label class="text-[10px] font-bold text-muted-dark uppercase tracking-widest">Classification</label>
              <select v-model="type" class="input font-medium uppercase text-xs">
                <option value="asset">Asset</option>
                <option value="liability">Liability</option>
                <option value="equity">Equity</option>
                <option value="income">Income</option>
                <option value="expense">Expense</option>
              </select>
            </div>
            <div class="space-y-1.5">
              <label class="text-[10px] font-bold text-muted-dark uppercase tracking-widest">Reporting Category</label>
              <select v-model="categoryId" class="input font-medium uppercase text-xs" :disabled="fetchingMetadata">
                <option v-for="cat in filteredCategories" :key="cat.id" :value="cat.id">
                  {{ cat.label }}
                </option>
              </select>
            </div>
          </div>

          <div class="pt-4 border-t border-border">
            <button 
              @click="submitAccount" 
              :disabled="loading || !code || !name || !categoryId"
              class="btn btn-primary w-full h-10 shadow-lg shadow-primary/10"
            >
              <Loader2 v-if="loading" class="w-4 h-4 animate-spin" />
              <span class="uppercase tracking-widest font-bold">Register New Account</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Info/Preview Sidebar -->
      <div class="space-y-6">
        <div class="card p-5 bg-slate-50 border-dashed">
          <h3 class="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-4">Configuration Rules</h3>
          <ul class="space-y-3">
            <li class="flex items-start gap-3">
              <div class="w-1 h-1 rounded-full bg-primary mt-1.5 shrink-0"></div>
              <p class="text-[11px] text-muted-dark leading-tight uppercase font-medium">Assets & Expenses carry a <span class="text-text font-bold">Debit</span> normal balance.</p>
            </li>
            <li class="flex items-start gap-3">
              <div class="w-1 h-1 rounded-full bg-primary mt-1.5 shrink-0"></div>
              <p class="text-[11px] text-muted-dark leading-tight uppercase font-medium">Liabilities, Equity & Income carry a <span class="text-text font-bold">Credit</span> normal balance.</p>
            </li>
          </ul>
        </div>

        <div class="card p-5 bg-indigo-50 border-indigo-100">
          <div class="flex items-center gap-3 mb-3">
            <Users class="w-4 h-4 text-indigo-600" />
            <h4 class="text-[10px] font-bold text-indigo-900 uppercase tracking-widest">Hierarchy Note</h4>
          </div>
          <p class="text-[11px] text-indigo-700 leading-relaxed uppercase tracking-tight font-medium">
            New accounts are immediately available for selection in journal entry distributions once registered.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
