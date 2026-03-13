<script setup>
import { 
  ShoppingCart, 
  Trash2, 
  X, 
  ChevronRight,
  Loader2,
  Check
} from 'lucide-vue-next'
import { usePosStore } from '../stores/posStore'

const props = defineProps({
  isOpen: Boolean
})

const emit = defineEmits(['close'])

const store = usePosStore()

const handleClear = () => {
  if (confirm('RESET ORDER? This will remove all items from the current cart.')) {
    store.clearCart()
  }
}

const handleCheckout = async () => {
  await store.checkout()
  emit('close')
}
</script>

<template>
  <aside 
    :class="[
      'fixed inset-y-0 right-0 z-50 w-full sm:w-[400px] lg:w-[420px] bg-surface border-l border-border flex flex-col shadow-2xl transition-transform duration-500 lg:relative lg:translate-x-0',
      isOpen ? 'translate-x-0' : 'translate-x-full'
    ]"
  >
    <!-- Cart Header -->
    <div class="h-16 lg:h-20 px-6 border-b border-border flex justify-between items-center bg-bg/20">
      <div class="flex items-center gap-4">
        <button @click="$emit('close')" class="lg:hidden h-10 w-10 flex items-center justify-center bg-bg border border-border text-muted hover:text-white transition-colors">
          <ChevronRight class="w-5 h-5 rotate-180" />
        </button>
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 bg-primary/10 flex items-center justify-center border border-primary/20">
            <ShoppingCart class="w-4 h-4 text-primary" />
          </div>
          <h2 class="text-[11px] font-black uppercase tracking-[0.2em]">Live Order</h2>
        </div>
      </div>
      <button 
        @click="handleClear" 
        class="text-[9px] font-black text-muted hover:text-danger flex items-center gap-1.5 transition-colors uppercase tracking-[0.2em]"
      >
        <Trash2 class="w-3.5 h-3.5" />
        Reset Order
      </button>
    </div>

    <!-- Cart Items: Ledger Style -->
    <div class="flex-1 overflow-y-auto p-0 custom-scrollbar bg-bg/5 divide-y divide-border">
      <div v-if="store.cart.length === 0" class="h-full flex flex-col items-center justify-center text-muted p-10">
        <div class="w-20 h-20 border border-dashed border-border flex items-center justify-center mb-6 bg-surface/30">
          <ShoppingCart class="w-6 h-6 opacity-10" />
        </div>
        <p class="text-[10px] font-black uppercase tracking-[0.4em]">Cart Empty</p>
        <p class="text-[9px] font-bold uppercase tracking-widest mt-2 opacity-30 italic">Select items to begin</p>
      </div>
      
      <TransitionGroup name="cart-item">
        <div 
          v-for="(item, index) in store.cart" 
          :key="item.id || index" 
          class="group flex items-center gap-4 bg-bg/20 p-4 hover:bg-bg/40 transition-all duration-300"
        >
          <div class="flex-1 min-w-0">
            <h4 class="text-[11px] font-black uppercase tracking-widest text-text-secondary truncate leading-none mb-2">{{ item.name }}</h4>
            <div class="flex items-center gap-3">
              <span class="text-[9px] font-black font-mono text-muted uppercase border border-border px-1.5 py-0.5 bg-bg/50">x{{ item.quantity }}</span>
              <span class="text-[9px] font-black font-mono text-muted-dark uppercase tracking-tighter">@{{ item.price.toFixed(2) }}</span>
            </div>
          </div>
          <div class="flex items-center gap-6">
            <span class="font-mono text-primary font-black text-sm tracking-tighter leading-none">{{store.currency}}{{ (item.price * item.quantity).toFixed(2) }}</span>
            <button 
              @click="store.removeFromCart(index)" 
              class="h-8 w-8 flex items-center justify-center bg-bg border border-border text-muted hover:text-danger hover:border-danger/30 transition-all opacity-0 group-hover:opacity-100"
            >
              <X class="w-4 h-4" />
            </button>
          </div>
        </div>
      </TransitionGroup>
    </div>

    <!-- Cart Footer: High Prominence -->
    <div class="p-8 lg:p-10 bg-bg border-t border-border space-y-8 shadow-[0_-20px_50px_rgba(0,0,0,0.3)]">
      <div class="flex justify-between items-end">
        <div class="space-y-1">
          <span class="text-[9px] font-black text-muted uppercase tracking-[0.4em] block opacity-60">Grand Total</span>
          <div class="flex items-baseline gap-1 relative text-text">
            <span class="text-xs font-black text-primary uppercase absolute -left-5 top-1 opacity-80">{{store.currency}}</span>
            <span class="text-6xl font-black font-mono tracking-tighter leading-none">{{ store.cartTotal.toFixed(2) }}</span>
          </div>
        </div>
        <div class="text-right flex flex-col items-end">
           <span class="text-[9px] font-black text-muted uppercase tracking-[0.4em] block mb-1 opacity-60">Items</span>
           <span class="text-2xl font-black font-mono text-text-secondary leading-none">{{ store.cartCount }}</span>
        </div>
      </div>
      
      <button 
        @click="handleCheckout"
        :disabled="store.loading || store.cart.length === 0"
        class="w-full h-20 bg-primary text-bg font-black text-[12px] tracking-[0.4em] transition-all flex items-center justify-center gap-4 disabled:opacity-5 hover:bg-primary-hover active:scale-[0.98] shadow-2xl shadow-primary/10 border-b-4 border-black/20"
      >
        <Loader2 v-if="store.loading" class="w-6 h-6 animate-spin" />
        <Check v-else class="w-6 h-6" />
        {{ store.loading ? 'PROCESSING...' : 'PROCESS CHECKOUT' }}
      </button>
    </div>
  </aside>
</template>

<style scoped>
.cart-item-move {
  transition: transform 0.4s ease;
}
</style>
