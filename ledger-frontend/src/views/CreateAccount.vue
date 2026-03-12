<script setup>
import { ref, watch, onMounted, computed } from 'vue'
import { Users, RefreshCw, Loader2, CheckCircle, AlertCircle, ShieldPlus, ArrowRight } from 'lucide-vue-next'

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
    
    setTimeout(() => {
      isSuccess.value = false
    }, 4000)
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
  <div class="space-y-4 animate-fade-in pb-8">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-end md:justify-between gap-3 border-b border-border pb-4">
      <div>
        <div class="flex items-center gap-2 mb-1">
          <ShieldPlus class="w-4 h-4 text-primary" />
          <span class="text-[10px] font-black text-muted uppercase tracking-[0.2em]">Chart of Accounts Setup</span>
        </div>
        <h1 class="text-2xl font-black text-text tracking-tighter uppercase">Initialize Account</h1>
      </div>
      <button @click="refresh" class="btn btn-outline h-8 px-3">
        <RefreshCw class="w-3 h-3" :class="{ 'animate-spin': fetchingMetadata }" />
        <span class="text-[10px] font-black uppercase tracking-widest ml-1">Sync Meta</span>
      </button>
    </div>

    <!-- Success Message -->
    <Transition name="fade">
      <div v-if="isSuccess" class="card bg-success/5 border-success/30 flex items-center gap-3 p-4 shadow-glow-success">
        <div class="w-8 h-8 rounded-full bg-success/20 flex items-center justify-center">
          <CheckCircle class="w-5 h-5 text-success" />
        </div>
        <div>
          <p class="text-[10px] font-black text-success uppercase tracking-widest">Initialization Success</p>
          <p class="text-[11px] text-muted-dark font-bold uppercase tracking-tighter mt-0.5">Account registered in master hierarchy.</p>
        </div>
      </div>
    </Transition>

    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
      <!-- Form -->
      <div class="lg:col-span-7">
        <div class="card bg-surface/50 p-6 space-y-6 shadow-xl border-border">
          <div class="space-y-5">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div class="space-y-1">
                <label class="text-[9px] font-black text-muted-dark uppercase tracking-widest">Account Code</label>
                <input 
                  v-model="code" 
                  type="text" 
                  placeholder="CODE_1XXX" 
                  class="input font-mono uppercase font-black tracking-widest h-9"
                />
              </div>
              <div class="md:col-span-2 space-y-1">
                <label class="text-[9px] font-black text-muted-dark uppercase tracking-widest">Operational Name</label>
                <input 
                  v-model="name" 
                  type="text" 
                  placeholder="e.g. Petty Cash Reserve" 
                  class="input font-bold h-9"
                />
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="space-y-1">
                <label class="text-[9px] font-black text-muted-dark uppercase tracking-widest">Classification Type</label>
                <select v-model="type" class="select font-bold uppercase tracking-tight h-9">
                  <option value="asset">Economic Asset</option>
                  <option value="liability">Current Liability</option>
                  <option value="equity">Shareholder Equity</option>
                  <option value="income">Operational Revenue</option>
                  <option value="expense">Administrative Expense</option>
                </select>
              </div>
              <div class="space-y-1">
                <label class="text-[9px] font-black text-muted-dark uppercase tracking-widest">Reporting Category</label>
                <select 
                  v-model="categoryId" 
                  class="select font-bold uppercase tracking-tight h-9"
                  :disabled="fetchingMetadata"
                >
                  <option v-if="fetchingMetadata" disabled>Querying Metadata...</option>
                  <option v-else-if="filteredCategories.length === 0" disabled>No categories found</option>
                  <option v-for="cat in filteredCategories" :key="cat.id" :value="cat.id">
                    {{ cat.label.toUpperCase() }}
                  </option>
                </select>
              </div>
            </div>

            <div class="space-y-2 pt-2">
              <label class="text-[9px] font-black text-muted-dark uppercase tracking-widest block">Primary Normal Balance</label>
              <div class="flex gap-2">
                <button 
                  @click="normalBalance = 'debit'"
                  :class="[
                    'flex-1 py-2 px-3 rounded border font-black text-[10px] uppercase tracking-[0.2em] transition-all duration-200',
                    normalBalance === 'debit' 
                      ? 'bg-success/10 border-success text-success shadow-glow-success' 
                      : 'bg-background/50 border-border text-muted-dark hover:border-muted/50'
                  ]"
                >
                  Debit (DR)
                </button>
                <button 
                  @click="normalBalance = 'credit'"
                  :class="[
                    'flex-1 py-2 px-3 rounded border font-black text-[10px] uppercase tracking-[0.2em] transition-all duration-200',
                    normalBalance === 'credit' 
                      ? 'bg-danger/10 border-danger text-danger shadow-glow-danger' 
                      : 'bg-background/50 border-border text-muted-dark hover:border-muted/50'
                  ]"
                >
                  Credit (CR)
                </button>
              </div>
            </div>
          </div>

          <div class="pt-4 border-t border-border">
            <button 
              @click="submitAccount"
              :disabled="loading || !code || !name || !categoryId"
              class="btn btn-primary w-full h-10"
            >
              <Loader2 v-if="loading" class="w-3.5 h-3.5 animate-spin" />
              <ShieldPlus v-else class="w-3.5 h-3.5" />
              <span class="text-[10px] font-black uppercase tracking-[0.2em] ml-2">{{ loading ? 'Processing...' : 'Register Account' }}</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Preview / Helper -->
      <div class="lg:col-span-5 space-y-4">
        <div class="card bg-background/30 border-dashed p-5">
          <h3 class="text-[9px] font-black text-muted-dark uppercase tracking-widest mb-3">Live Hierarchy Preview</h3>
          <div class="space-y-3">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded bg-surface border border-border flex items-center justify-center font-mono font-black text-primary uppercase text-[9px]">
                {{ code || '?' }}
              </div>
              <div>
                <p class="text-[12px] font-bold text-text uppercase tracking-tight">{{ name || 'Specified Account Name' }}</p>
                <p class="text-[8px] font-black text-muted uppercase tracking-widest mt-0.5">{{ type }} | {{ normalBalance }} balance</p>
              </div>
            </div>
            <div class="h-[1px] bg-border/50"></div>
            <p class="text-[9px] text-muted-dark font-bold uppercase tracking-tighter leading-tight">
              Registering this account will update the general ledger distributions and available targets for journal entries.
            </p>
          </div>
        </div>

        <div class="card bg-primary/5 border-primary/10 p-5">
          <div class="flex items-start gap-3">
            <div class="w-7 h-7 rounded bg-primary/10 flex items-center justify-center flex-shrink-0">
              <ArrowRight class="w-3.5 h-3.5 text-primary" />
            </div>
            <div>
              <h4 class="text-[10px] font-black text-text uppercase tracking-widest">Configuration Rules</h4>
              <ul class="mt-2 space-y-1.5">
                <li class="text-[9px] text-muted-dark font-bold uppercase tracking-tighter flex items-center gap-2">
                  <div class="w-1 h-1 rounded-full bg-primary"></div>
                  Asset & Expense use Debit as normal
                </li>
                <li class="text-[9px] text-muted-dark font-bold uppercase tracking-tighter flex items-center gap-2">
                  <div class="w-1 h-1 rounded-full bg-primary"></div>
                  Liability & Equity use Credit as normal
                </li>
                <li class="text-[9px] text-muted-dark font-bold uppercase tracking-tighter flex items-center gap-2">
                  <div class="w-1 h-1 rounded-full bg-primary"></div>
                  Revenue uses Credit as normal
                </li>
              </ul>
            </div>
          </div>
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
