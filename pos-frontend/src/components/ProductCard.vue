<script setup>
import { computed } from 'vue'
import { Plus } from 'lucide-vue-next'
import { usePosStore } from '../stores/posStore'

const props = defineProps({
  product: {
    type: Object,
    required: true
  }
})

const store = usePosStore()

const quantityInCart = computed(() => {
  const item = store.cart.find(i => i.id === props.product.id)
  return item ? item.quantity : 0
})
</script>

<template>
  <div 
    @click="store.addToCart(product)"
    class="card-industrial group cursor-pointer relative flex flex-col h-full animate-scale-in"
  >
    <!-- Product Image -->
    <div class="aspect-square bg-bg/50 mb-3 overflow-hidden relative border border-border group-hover:border-primary/20 transition-all duration-500">
      <img 
        :src="store.imageBaseUrl + product.img_url" 
        :alt="product.name"
        class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700 opacity-80 group-hover:opacity-100" 
      />
      <div class="absolute inset-0 bg-gradient-to-t from-bg/20 to-transparent opacity-40"></div>
      
      <!-- Quantity Badge -->
      <div 
        v-if="quantityInCart > 0"
        class="absolute top-2 right-2 min-w-[20px] h-[20px] px-1 bg-primary flex items-center justify-center shadow-xl border border-primary/20 animate-scale-in"
      >
        <span class="text-[9px] font-black font-mono text-bg">{{ quantityInCart }}</span>
      </div>

      <!-- Add Hover Indicator -->
      <div class="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300">
        <div class="w-10 h-10 bg-primary flex items-center justify-center shadow-2xl shadow-primary/40 transform scale-75 group-hover:scale-100 transition-transform duration-300">
          <Plus class="w-5 h-5 text-bg" />
        </div>
      </div>
    </div>
    
    <!-- Product Info -->
    <div class="flex-1 flex flex-col justify-between space-y-2">
      <h3 class="font-black text-[10px] uppercase tracking-widest text-text-muted group-hover:text-primary transition-colors leading-tight">
        {{ product.name }}
      </h3>
      <div class="flex items-center justify-between gap-2 border-t border-border pt-2">
        <span class="text-xs font-black font-mono text-text tracking-tighter leading-none bg-surface-elevated px-2 py-1 border border-border">
          <span class="text-primary text-[9px] mr-0.5 opacity-70">{{store.currency}}</span>{{ product.price.toFixed(2) }}
        </span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.animate-scale-in {
  animation: scaleIn 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes scaleIn {
  from { opacity: 0; transform: scale(0.95); }
  to { opacity: 1; transform: scale(1); }
}
</style>
