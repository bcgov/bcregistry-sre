<script setup>
useHead({
  meta: [
    { name: 'viewport', content: 'width=device-width, initial-scale=1' }
  ],
  link: [
    { rel: 'icon', href: '/favicon.svg' }
  ],
  htmlAttrs: {
    lang: 'en'
  }
})

const title = 'Nuxt-GCP Telemetry'
const description = 'An approach that enables browser based client logging to be sent to the same log and telemetry store that the back end services enjoy.'

useSeoMeta({
  title,
  description,
  ogTitle: title,
  ogDescription: description,
  ogImage: ''
})
</script>

<template>
  <UApp>
    <UHeader>
      <template #left>
        <NuxtLink to="/">
          <AppLogo class="w-auto h-6 shrink-0" />
        </NuxtLink>
      </template>

      <template #right>
        <UColorModeButton />

        <UButton
          to="https://github.com/nuxt-ui-templates/starter"
          target="_blank"
          aria-label="GitHub"
          color="neutral"
          variant="ghost"
          :avatar="{
            src: '/tangled.webp',
            loading: 'lazy'
          }"
        />
      </template>
    </UHeader>

    <UMain>
      <NuxtPage />
    </UMain>

    <USeparator icon="i-simple-icons-nuxtdotjs" />

    <UFooter>
      <template #left>
        <p class="text-sm text-muted">
          Built with Nuxt UI • © {{ new Date().getFullYear() }}
        </p>
      </template>

      <template #right>
        <UButton
          to="https://github.com/nuxt-ui-templates/starter"
          target="_blank"
          aria-label="GitHub"
          color="neutral"
          variant="ghost"
          :avatar="{
            src: '/tangled.webp',
            loading: 'lazy'
          }"
        />
      </template>
    </UFooter>
  </UApp>
</template>
