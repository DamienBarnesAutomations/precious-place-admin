<script setup>
import { reactive, ref } from 'vue'
import { 
  UserPlus, 
  Shield, 
  MessageSquare, 
  ChevronRight, 
  Loader2 
} from 'lucide-vue-next'
import { usePosStore } from '../stores/posStore'

const props = defineProps({
  showSelection: Boolean,
  showCreate: Boolean,
  userType: String
})

const emit = defineEmits(['closeSelection', 'closeCreate', 'selectType'])

const store = usePosStore()
const isSubmitting = ref(false)

const userForm = reactive({
  username: '',
  password: '',
  userId: ''
})

const handleCreateUser = async () => {
  const url = props.userType === 'site' ? store.createAdminUserUrl : store.createChatAdminUserUrl
  
  if (!url) {
    alert('SYSTEM_ERROR: AUTH_URL_NOT_CONFIGURED')
    return
  }

  isSubmitting.value = true
  try {
    const payload = props.userType === 'site' 
      ? { username: userForm.username, password: userForm.password }
      : { userId: userForm.userId }

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })

    if (response.ok) {
      alert('Success: User account active.')
      emit('closeCreate')
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
</script>

<template>
  <div>
    <!-- Selection Dialog -->
    <div v-if="showSelection" class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/98 backdrop-blur-3xl">
      <div class="bg-surface border border-border w-full max-w-sm p-10 shadow-[0_0_100px_rgba(0,0,0,0.8)] animate-scale-in rounded-none">
        <h3 class="text-xs font-black text-text uppercase tracking-[0.4em] text-center mb-10 opacity-80">Access Management</h3>
        <div class="space-y-4">
          <button 
            @click="$emit('selectType', 'site')" 
            class="w-full h-20 bg-bg border border-border hover:border-primary/50 transition-all flex items-center justify-between px-8 group uppercase tracking-[0.2em]"
          >
            <span class="flex items-center gap-5">
              <Shield class="w-5 h-5 text-muted group-hover:text-primary transition-colors" />
              <span class="text-[10px] font-black">Site Admin</span>
            </span>
            <ChevronRight class="w-4 h-4 text-muted group-hover:text-primary transition-transform group-hover:translate-x-1" />
          </button>
          <button 
            @click="$emit('selectType', 'chat')" 
            class="w-full h-20 bg-bg border border-border hover:border-primary/50 transition-all flex items-center justify-between px-8 group uppercase tracking-[0.2em]"
          >
            <span class="flex items-center gap-5">
              <MessageSquare class="w-5 h-5 text-muted group-hover:text-primary transition-colors" />
              <span class="text-[10px] font-black">Chat Admin</span>
            </span>
            <ChevronRight class="w-4 h-4 text-muted group-hover:text-primary transition-transform group-hover:translate-x-1" />
          </button>
          <button 
            @click="$emit('closeSelection')" 
            class="w-full py-6 text-[9px] font-black text-muted hover:text-white uppercase tracking-[0.4em] transition-colors mt-6"
          >
            Abort Operation
          </button>
        </div>
      </div>
    </div>

    <!-- Create User Dialog -->
    <div v-if="showCreate" class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/98 backdrop-blur-3xl">
      <div class="bg-surface border border-border w-full max-w-md p-10 shadow-2xl animate-scale-in rounded-none">
        <div class="flex items-center gap-6 mb-12">
          <div class="w-14 h-14 bg-primary/10 flex items-center justify-center border border-primary/20">
            <UserPlus class="w-8 h-8 text-primary" />
          </div>
          <div>
            <h3 class="text-xs font-black text-text uppercase tracking-[0.4em]">Register Admin</h3>
            <p class="text-[9px] font-bold text-muted uppercase tracking-[0.2em] mt-1.5 italic opacity-60">Security Level: {{ userType === 'site' ? 'SITE_ADMIN' : 'CHAT_ADMIN' }}</p>
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
                placeholder="ADMIN_ID" 
                class="input-industrial w-full h-14"
              />
            </div>
            <div class="space-y-3">
              <label class="text-[9px] font-black text-muted uppercase tracking-[0.4em] ml-1 opacity-60">Access Key</label>
              <input 
                v-model="userForm.password" 
                type="password" 
                required 
                placeholder="••••••••" 
                class="input-industrial w-full h-14 font-mono tracking-widest"
              />
            </div>
          </template>
          <template v-else>
            <div class="space-y-3">
              <label class="text-[9px] font-black text-muted uppercase tracking-[0.4em] ml-1 opacity-60">Messenger ID</label>
              <input 
                v-model="userForm.userId" 
                type="text" 
                required 
                placeholder="CHAT_USER_ID" 
                class="input-industrial w-full h-14"
              />
            </div>
          </template>
          
          <div class="flex gap-4 pt-8">
            <button 
              type="button" 
              @click="$emit('closeCreate')" 
              class="flex-1 h-14 bg-bg border border-border hover:bg-white/5 text-muted hover:text-white transition-all uppercase text-[9px] font-black tracking-[0.3em]"
            >
              Cancel
            </button>
            <button 
              type="submit" 
              :disabled="isSubmitting"
              class="flex-1 h-14 bg-primary hover:bg-primary-hover disabled:opacity-20 text-bg transition-all flex items-center justify-center gap-3 uppercase text-[9px] font-black tracking-[0.3em] shadow-xl shadow-primary/10"
            >
              <Loader2 v-if="isSubmitting" class="w-4 h-4 animate-spin" />
              Activate
            </button>
          </div>
        </form>
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
