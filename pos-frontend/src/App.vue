<script setup>
import { onMounted, ref, computed, reactive } from 'vue'
import { usePosStore } from './stores/posStore'
import { 
  ShoppingCart, 
  Search, 
  X, 
  Plus, 
  Trash2, 
  TrendingUp, 
  UserPlus, 
  Users, 
  ChevronDown,
  ChevronRight,
  Check,
  Loader2,
  Shield,
  MessageSquare,
  PackageSearch
} from 'lucide-vue-next'

const store = usePosStore()
const isMobileCartOpen = ref(false)
const searchQuery = ref('')
const showUserDialog = ref(false)
const showSelectionDialog = ref(false)
const isSubmitting = ref(false)
const userType = ref('site') // 'site' or 'chat'

const userForm = reactive({
  username: '',
  password: '',
  userId: ''
})

const openCreateUser = () => {
  showSelectionDialog.value = true
}

const selectType = (type) => {
  userType.value = type
  showSelectionDialog.value = false
  showUserDialog.value = true
}

const handleCreateUser = async () => {
  const url = userType.value === 'site' ? store.createAdminUserUrl : store.createChatAdminUserUrl
  
  if (!url) {
    alert('SYSTEM_ERROR: AUTH_URL_NOT_CONFIGURED')
    return
  }

  isSubmitting.value = true
  try {
    const payload = userType.value === 'site' 
      ? { username: userForm.username, password: userForm.password }
      : { userId: userForm.userId }

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })

    if (response.ok) {
      alert('Success: User account active.')
      showUserDialog.value = false
      userForm.username = ''
      userForm.password = ''
      userForm.userId = ''
    } else {
      const errorData = await response.json().catch(() => ({}))
      alert(`Failure: ${errorData.message || response.statusText}`)
    }
  } catch (error) {
    console.error('Error creating user:', error)
    alert('System error: Authorization service unreachable.')
  } finally {
    isSubmitting.value = false
  }
}

const filteredProducts = computed(() => {
  if (!searchQuery.value.trim()) return store.products
  return store.products.filter(p =>
    p.name.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

onMounted(() => {
  if (store.fetchProducts) store.fetchProducts()
})
</script>

<template>
  <div class="flex flex-col lg:flex-row h-screen bg-bg text-zinc-100 overflow-hidden font-sans select-none">
    
    <!-- Main Content Area -->
    <main class="flex-1 flex flex-col min-w-0 overflow-hidden">
      <!-- Header: Glass Panel -->
      <header class="glass-panel h-16 lg:h-20 flex items-center justify-between px-4 lg:px-8 shrink-0 z-20 shadow-xl">
        <div class="flex items-center gap-4 lg:gap-6">
          <div class="relative group">
            <div class="absolute inset-0 bg-primary/20 blur-xl rounded-full group-hover:bg-primary/30 transition-all duration-500"></div>
            <img 
              :src="store.logo" 
              alt="Logo" 
              class="relative w-10 h-10 lg:w-12 lg:h-12 object-contain brightness-0 invert transition-transform group-hover:scale-110 duration-500" 
            />
          </div>
          <div class="hidden sm:block">
            <h1 class="text-lg lg:text-xl font-black tracking-tighter uppercase leading-none">{{store.appTitle}}</h1>
            <p class="text-[10px] font-bold text-muted uppercase tracking-[0.2em] mt-1 italic opacity-60">Bakery Sales Terminal</p>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <!-- Create User -->
          <button @click="openCreateUser" class="btn-base bg-surface border border-border hover:border-primary/50 hover:text-primary h-10 w-10 p-0" title="Add Admin User">
            <UserPlus class="w-4 h-4" />
          </button>

          <!-- Daily Sales -->
          <button @click="store.fetchDailySales()" class="btn-base bg-surface border border-border hover:border-primary/50 hover:text-primary h-10 w-10 p-0" title="View Daily Sales">
            <TrendingUp class="w-4 h-4" />
          </button>

          <!-- Mobile Cart Toggle -->
          <button 
            @click="isMobileCartOpen = true" 
            class="lg:hidden relative h-10 px-4 bg-primary/10 border border-primary/30 rounded-lg text-primary flex items-center gap-2"
          >
            <ShoppingCart class="w-4 h-4" />
            <span class="font-mono font-black text-sm">{{ store.cartCount }}</span>
          </button>
        </div>
      </header>

      <!-- Sub-Header: Search -->
      <div class="px-4 lg:px-8 py-4 lg:py-6 border-b border-border bg-surface/30">
        <div class="max-w-3xl relative group">
          <Search class="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-muted group-focus-within:text-primary transition-colors" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="SEARCH FOR PRODUCTS..."
            class="input-industrial w-full pl-12 h-12 bg-bg/80 uppercase font-black tracking-tight text-xs"
          />
          <div class="absolute right-4 top-1/2 -translate-y-1/2 flex items-center gap-2">
             <button v-if="searchQuery" @click="searchQuery = ''" class="text-muted hover:text-white transition-colors">
               <X class="w-4 h-4" />
             </button>
          </div>
        </div>
      </div>
      
      <!-- Products Grid -->
      <div class="flex-1 overflow-y-auto p-4 lg:p-8 custom-scrollbar bg-bg/20">
        <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 xl:grid-cols-5 2xl:grid-cols-6 gap-4 lg:gap-6 max-w-[1600px] mx-auto pb-12">
          <div 
            v-for="product in filteredProducts" 
            :key="product.id"
            @click="store.addToCart(product)"
            class="card-industrial group cursor-pointer relative flex flex-col animate-scale-in"
          >
            <div class="aspect-square bg-bg/50 rounded-lg mb-4 overflow-hidden relative border border-border group-hover:border-primary/20 transition-all duration-500">
              <img 
                :src="store.imageBaseUrl + product.img_url" 
                class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700 opacity-80 group-hover:opacity-100" 
              />
              <div class="absolute inset-0 bg-gradient-to-t from-bg to-transparent opacity-40"></div>
              <div class="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                <div class="w-12 h-12 rounded-full bg-primary flex items-center justify-center shadow-2xl shadow-primary/40 transform scale-75 group-hover:scale-100 transition-transform duration-300">
                  <Plus class="w-6 h-6 text-bg" />
                </div>
              </div>
            </div>
            
            <div class="flex-1 space-y-2">
              <h3 class="font-black text-[10px] lg:text-[11px] uppercase tracking-[0.15em] text-zinc-400 group-hover:text-primary transition-colors truncate">
                {{ product.name }}
              </h3>
              <div class="flex items-center justify-between">
                <span class="text-xl font-black font-mono text-zinc-100 tracking-tighter leading-none">
                  <span class="text-primary text-[10px] mr-0.5 opacity-70">{{store.currency}}</span>{{ product.price.toFixed(2) }}
                </span>
              </div>
            </div>
          </div>

          <!-- Empty State -->
          <div v-if="filteredProducts.length === 0 && searchQuery" class="col-span-full py-32 flex flex-col items-center justify-center text-muted border border-dashed border-border rounded-2xl bg-surface/5">
            <div class="w-20 h-20 rounded-full bg-surface/50 border border-border flex items-center justify-center mb-6">
              <PackageSearch class="w-10 h-10 opacity-20" />
            </div>
            <p class="text-xs font-black uppercase tracking-[0.3em]">No products found</p>
            <p class="text-[10px] font-bold uppercase tracking-tight mt-2 opacity-40">No matching items for "{{ searchQuery }}".</p>
          </div>
        </div>
      </div>
    </main>

    <!-- Cart Sidebar -->
    <aside 
      :class="[
        'fixed inset-y-0 right-0 z-50 w-full sm:w-[400px] lg:w-[420px] bg-surface border-l border-border flex flex-col shadow-2xl transition-transform duration-500 lg:relative lg:translate-x-0',
        isMobileCartOpen ? 'translate-x-0' : 'translate-x-full'
      ]"
    >
      <!-- Cart Header -->
      <div class="h-16 lg:h-20 px-6 border-b border-border flex justify-between items-center bg-bg/20">
        <div class="flex items-center gap-4">
          <button @click="isMobileCartOpen = false" class="lg:hidden h-10 w-10 flex items-center justify-center bg-bg border border-border rounded-lg text-muted hover:text-white transition-colors">
            <ChevronRight class="w-5 h-5 rotate-180" />
          </button>
          <div class="flex items-center gap-3">
            <div class="w-8 h-8 rounded bg-primary/10 flex items-center justify-center border border-primary/20">
              <ShoppingCart class="w-4 h-4 text-primary" />
            </div>
            <h2 class="text-xs font-black uppercase tracking-[0.2em]">Current Order</h2>
          </div>
        </div>
        <button 
          @click="store.clearCart" 
          class="text-[9px] font-black text-muted hover:text-danger flex items-center gap-1.5 transition-colors uppercase tracking-[0.2em]"
        >
          <Trash2 class="w-3.5 h-3.5" />
          Clear Order
        </button>
      </div>

      <!-- Cart Items -->
      <div class="flex-1 overflow-y-auto p-6 space-y-1.5 custom-scrollbar bg-bg/5">
        <div v-if="store.cart.length === 0" class="h-full flex flex-col items-center justify-center text-muted">
          <div class="w-24 h-24 rounded-full border border-dashed border-border flex items-center justify-center mb-8 bg-surface/30">
            <ShoppingCart class="w-8 h-8 opacity-10" />
          </div>
          <p class="text-[10px] font-black uppercase tracking-[0.4em]">Cart is empty</p>
          <p class="text-[9px] font-bold uppercase tracking-widest mt-2 opacity-30 italic leading-none">Select products to begin...</p>
        </div>
        
        <TransitionGroup name="cart-item">
          <div 
            v-for="(item, index) in store.cart" 
            :key="index" 
            class="group flex items-center gap-4 bg-bg/40 p-3 rounded border border-border/50 hover:border-primary/30 transition-all duration-300"
          >
            <div class="flex-1 min-w-0">
              <h4 class="text-[11px] font-black uppercase tracking-tight text-zinc-300 truncate">{{ item.name }}</h4>
              <div class="flex items-center gap-2 mt-1.5">
                <span class="text-[9px] font-bold font-mono text-muted uppercase">Qty: {{ item.quantity }}</span>
                <span class="w-1 h-1 rounded-full bg-border"></span>
                <span class="text-[9px] font-bold font-mono text-muted uppercase">Unit: {{ item.price.toFixed(2) }}</span>
              </div>
            </div>
            <div class="flex items-center gap-4">
              <span class="font-mono text-primary font-black text-sm tracking-tighter leading-none">{{store.currency}}{{ (item.price * item.quantity).toFixed(2) }}</span>
              <button 
                @click="store.removeFromCart(index)" 
                class="h-8 w-8 flex items-center justify-center bg-bg border border-border rounded text-muted hover:text-danger hover:border-danger/30 transition-all opacity-0 group-hover:opacity-100"
              >
                <X class="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        </TransitionGroup>
      </div>

      <!-- Cart Footer -->
      <div class="p-6 lg:p-10 bg-bg border-t border-border space-y-8 shadow-[0_-20px_50px_rgba(0,0,0,0.3)]">
        <div class="flex justify-between items-end">
          <div class="space-y-2">
            <span class="text-[9px] font-black text-muted uppercase tracking-[0.4em] block opacity-60">Total Amount</span>
            <div class="flex items-baseline gap-1 relative">
              <span class="text-xs font-black text-primary uppercase absolute -left-4 top-1">{{store.currency}}</span>
              <span class="text-6xl font-black text-white font-mono tracking-tighter leading-none">{{ store.cartTotal.toFixed(2) }}</span>
            </div>
          </div>
          <div class="text-right flex flex-col items-end">
             <span class="text-[9px] font-black text-muted uppercase tracking-[0.4em] block mb-1 opacity-60">Total Items</span>
             <span class="text-2xl font-black font-mono text-zinc-400 leading-none">{{ store.cartCount }}</span>
          </div>
        </div>
        <button 
          @click="store.checkout(); isMobileCartOpen = false"
          :disabled="store.loading || store.cart.length === 0"
          class="w-full h-16 bg-primary text-bg rounded font-black text-[11px] tracking-[0.3em] transition-all flex items-center justify-center gap-3 disabled:opacity-10 hover:bg-primary-hover active:scale-[0.98] shadow-2xl shadow-primary/10"
        >
          <Loader2 v-if="store.loading" class="w-5 h-5 animate-spin" />
          <Check v-else class="w-5 h-5" />
          {{ store.loading ? 'PROCESSING...' : 'CHECKOUT' }}
        </button>
      </div>
    </aside>

    <!-- Mobile Cart Overlay -->
    <div 
      v-if="isMobileCartOpen" 
      @click="isMobileCartOpen = false" 
      class="fixed inset-0 bg-black/90 backdrop-blur-md z-40 lg:hidden"
    ></div>

    <!-- Success Toast -->
    <Transition name="toast">
      <div 
        v-if="store.showSuccessToast" 
        class="fixed top-8 right-8 z-[100] bg-surface border-2 border-primary p-6 rounded shadow-2xl flex items-center gap-6 shadow-primary/20 animate-scale-in"
      >
        <div class="w-14 h-14 bg-primary/10 rounded flex items-center justify-center border border-primary/20">
          <Check class="w-8 h-8 text-primary" />
        </div>
        <div>
          <p class="text-xs font-black text-text uppercase tracking-[0.2em] leading-none mb-1.5">Sale Completed</p>
          <p class="text-[9px] font-bold text-muted uppercase tracking-widest leading-none">The order has been successfully recorded.</p>
        </div>
      </div>
    </Transition>

    <!-- Daily Sales Modal: Receipt Aesthetic -->
    <div v-if="store.showSalesModal" class="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/95 backdrop-blur-2xl">
      <div class="bg-surface border border-border w-full max-w-3xl rounded-lg flex flex-col max-h-[90vh] shadow-[0_0_80px_rgba(0,0,0,0.6)] overflow-hidden">
        <div class="p-6 border-b border-border flex justify-between items-center bg-bg/40">
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded bg-primary/10 flex items-center justify-center border border-primary/20">
              <TrendingUp class="w-6 h-6 text-primary" />
            </div>
            <div>
              <h2 class="text-sm font-black uppercase tracking-[0.3em]">Daily Sales Activity</h2>
              <p class="text-[10px] font-bold text-muted uppercase tracking-[0.2em] mt-1 italic">Date: {{ new Date().toLocaleDateString('en-GB') }}</p>
            </div>
          </div>
          <button @click="store.showSalesModal = false" class="h-12 w-12 flex items-center justify-center hover:bg-white/5 rounded transition-colors text-muted hover:text-white">
            <X class="w-6 h-6" />
          </button>
        </div>
        
        <div class="flex-1 overflow-y-auto p-8 space-y-6 custom-scrollbar bg-bg/10">
          <div v-if="!store.groupedSales || store.groupedSales.length === 0" class="py-32 flex flex-col items-center justify-center text-muted border-2 border-dashed border-border rounded">
            <TrendingUp class="w-16 h-16 mb-6 opacity-5" />
            <p class="text-[11px] font-black uppercase tracking-[0.4em]">No sales recorded today</p>
          </div>

          <div v-for="group in store.groupedSales" :key="group.id" class="border border-border/40 rounded bg-surface/30 overflow-hidden shadow-sm">
            <div @click="store.toggleTransaction(group.id)" class="p-5 flex justify-between items-center cursor-pointer hover:bg-primary/5 transition-all group">
              <div class="flex items-center gap-6">
                <span class="font-mono text-[11px] font-black text-primary/60 bg-bg px-3 py-1.5 rounded border border-border uppercase tracking-tighter leading-none">
                  {{ new Date(group.time).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit', second: '2-digit'}) }}
                </span>
                <span class="text-[11px] font-black text-zinc-200 uppercase tracking-[0.2em] italic opacity-80 group-hover:opacity-100 transition-opacity">ORDER_{{ group.id }}</span>
              </div>
              <div class="flex items-center gap-6">
                <span class="font-black text-primary font-mono text-xl tracking-tighter leading-none">{{ store.currency }}{{ group.total.toFixed(2) }}</span>
                <div class="w-8 h-8 rounded flex items-center justify-center border border-border group-hover:border-primary/20 transition-colors">
                  <ChevronDown 
                    class="w-5 h-5 text-muted transition-transform duration-500" 
                    :class="{'rotate-180 text-primary': store.expandedTransactions?.includes(group.id)}" 
                  />
                </div>
              </div>
            </div>

            <div v-if="store.expandedTransactions?.includes(group.id)" class="bg-bg/60 border-t border-border p-6 space-y-4 animate-scale-in">
              <div class="space-y-3">
                <div v-for="item in group.items" :key="item.id" class="flex justify-between items-center border-b border-border/20 pb-3 last:border-0 last:pb-0">
                  <div class="flex items-center gap-4">
                    <span class="text-[11px] font-black text-primary/40 font-mono w-10 shrink-0">{{ item.quantity }}x</span>
                    <span class="text-[11px] font-black text-zinc-400 uppercase tracking-tight italic">{{ item.name }}</span>
                  </div>
                  <span class="text-[11px] font-black font-mono text-muted tracking-tighter leading-none">{{ store.currency }}{{ Number(item.total_price).toFixed(2) }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="p-8 lg:p-10 border-t border-border bg-bg flex justify-between items-center shrink-0 shadow-[0_-10px_40px_rgba(0,0,0,0.4)]">
          <div class="space-y-2">
            <p class="text-muted text-[10px] font-black uppercase tracking-[0.4em] leading-none opacity-60">Total Sales Today</p>
            <p class="text-5xl font-black text-primary font-mono tracking-tighter leading-none">{{ store.currency }}{{ store.dayTotal.toFixed(2) }}</p>
          </div>
          <button 
            @click="store.showSalesModal = false" 
            class="h-14 px-10 bg-zinc-800 hover:bg-zinc-700 text-zinc-100 rounded font-black text-[11px] tracking-[0.3em] transition-all uppercase active:scale-95 shadow-2xl"
          >
            Close Report
          </button>
        </div>
      </div>
    </div>

    <!-- Selection Dialog -->
    <div v-if="showSelectionDialog" class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/98 backdrop-blur-3xl">
      <div class="bg-surface border border-border w-full max-w-sm rounded-lg p-10 shadow-[0_0_100px_rgba(0,0,0,0.8)] animate-scale-in">
        <h3 class="text-xs font-black text-text uppercase tracking-[0.3em] text-center mb-10 opacity-80">Add New User</h3>
        <div class="space-y-4">
          <button 
            @click="selectType('site')" 
            class="w-full h-16 bg-bg border border-border hover:border-primary/50 rounded font-black text-[10px] text-zinc-300 transition-all flex items-center justify-between px-8 group uppercase tracking-[0.2em]"
          >
            <span class="flex items-center gap-5">
              <Shield class="w-5 h-5 text-muted group-hover:text-primary transition-colors" />
              Add Site Admin
            </span>
            <ChevronRight class="w-4 h-4 text-muted group-hover:text-primary transition-transform group-hover:translate-x-1" />
          </button>
          <button 
            @click="selectType('chat')" 
            class="w-full h-16 bg-bg border border-border hover:border-primary/50 rounded font-black text-[10px] text-zinc-300 transition-all flex items-center justify-between px-8 group uppercase tracking-[0.2em]"
          >
            <span class="flex items-center gap-5">
              <MessageSquare class="w-5 h-5 text-muted group-hover:text-primary transition-colors" />
              Add Chat Admin
            </span>
            <ChevronRight class="w-4 h-4 text-muted group-hover:text-primary transition-transform group-hover:translate-x-1" />
          </button>
          <button 
            @click="showSelectionDialog = false" 
            class="w-full py-6 text-[9px] font-black text-muted hover:text-white uppercase tracking-[0.4em] transition-colors mt-6"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>

    <!-- Create User Dialog -->
    <div v-if="showUserDialog" class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/98 backdrop-blur-3xl">
      <div class="bg-surface border border-border w-full max-w-md rounded-lg p-10 shadow-2xl animate-scale-in">
        <div class="flex items-center gap-5 mb-10">
          <div class="w-12 h-12 rounded bg-primary/10 flex items-center justify-center border border-primary/20">
            <UserPlus class="w-6 h-6 text-primary" />
          </div>
          <div>
            <h3 class="text-xs font-black text-text uppercase tracking-[0.3em]">Add New User</h3>
            <p class="text-[9px] font-bold text-muted uppercase tracking-[0.2em] mt-1 italic opacity-60">Level: {{ userType === 'site' ? 'SITE_ADMIN' : 'CHAT_ADMIN' }}</p>
          </div>
        </div>
        <form @submit.prevent="handleCreateUser" class="space-y-8">
          <template v-if="userType === 'site'">
            <div class="space-y-3">
              <label class="text-[9px] font-black text-muted uppercase tracking-[0.4em] ml-1 opacity-60">Username</label>
              <input 
                v-model="userForm.username" 
                type="text" 
                required 
                placeholder="USERNAME" 
                class="input-industrial w-full font-mono uppercase font-black tracking-[0.2em] h-12"
              />
            </div>
            <div class="space-y-3">
              <label class="text-[9px] font-black text-muted uppercase tracking-[0.4em] ml-1 opacity-60">Password</label>
              <input 
                v-model="userForm.password" 
                type="password" 
                required 
                placeholder="••••••••" 
                class="input-industrial w-full font-mono tracking-widest h-12"
              />
            </div>
          </template>
          <template v-else>
            <div class="space-y-3">
              <label class="text-[9px] font-black text-muted uppercase tracking-[0.4em] ml-1 opacity-60">Chat User ID</label>
              <input 
                v-model="userForm.userId" 
                type="text" 
                required 
                placeholder="USER_ID" 
                class="input-industrial w-full font-mono uppercase font-black tracking-[0.2em] h-12"
              />
            </div>
          </template>
          
          <div class="flex gap-4 pt-6">
            <button 
              type="button" 
              @click="showUserDialog = false" 
              class="flex-1 h-14 bg-bg border border-border hover:bg-white/5 text-muted hover:text-white rounded font-black text-[9px] tracking-[0.3em] transition-all uppercase"
            >
              Cancel
            </button>
            <button 
              type="submit" 
              :disabled="isSubmitting"
              class="flex-1 h-14 bg-primary hover:bg-primary-hover disabled:opacity-10 text-bg rounded font-black text-[9px] tracking-[0.3em] transition-all flex items-center justify-center gap-2 uppercase shadow-xl shadow-primary/10"
            >
              <Loader2 v-if="isSubmitting" class="w-4 h-4 animate-spin" />
              Create User
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.animate-scale-in {
  animation: scaleIn 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

.animate-slide-down {
  animation: slideDown 0.3s ease-out;
}

@keyframes scaleIn {
  from { opacity: 0; transform: scale(0.95); }
  to { opacity: 1; transform: scale(1); }
}

@keyframes slideDown {
  from { opacity: 0; transform: translateY(-10px); }
  to { opacity: 1; transform: translateY(0); }
}

.cart-item-move {
  transition: transform 0.4s ease;
}
</style>