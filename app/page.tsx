'use client';

import { useState, useEffect } from 'react';
import { useTheme } from '@/components/ThemeProvider';
import { db } from '@/lib/firebase';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';

const GITHUB_API_URL = 'https://api.github.com/repos/tushal-pethani/lakhaan/releases/latest';
const GITHUB_REPO_URL = 'https://github.com/tushal-pethani/lakhaan/releases/latest';
const FEATURES = [
  {
    icon: '📄',
    title: 'GST Invoice Generation',
    desc: 'Create professional GST-compliant invoices in seconds',
  },
  {
    icon: '🔍',
    title: 'Auto-Fetch Client Details',
    desc: 'Auto-populate client info using GST number',
  },
  {
    icon: '🎨',
    title: 'Multiple Themes',
    desc: 'Choose from various invoice templates',
  },
  {
    icon: '🔒',
    title: 'Secure Authentication',
    desc: 'Firebase-backed secure user accounts',
  },
  {
    icon: '⚡',
    title: 'Fast Desktop App',
    desc: 'Lightweight and lightning-fast performance',
  },
];

const TRUST_POINTS = [
  { icon: '🔐', text: 'Secure Firebase authentication' },
  { icon: '🚫', text: 'No data sharing with third parties' },
  { icon: '🏪', text: 'Built for small businesses' },
  { icon: '💯', text: '100% free to use' },
];

const SCREENSHOTS = [
  { title: 'Dashboard', src: '/screenshots/dashboard.png', alt: 'Lakhaan Dashboard' },
  { title: 'Invoice Preview', src: '/screenshots/invoice-preview.png', alt: 'Invoice Preview' },
  { title: 'Client Management', src: '/screenshots/clients.png', alt: 'Client Management' },
];

interface ReleaseInfo {
  version: string;
  downloadUrl: string;
}

export default function HomePage() {
  const { resolvedTheme, setTheme } = useTheme();
  const [formData, setFormData] = useState({ name: '', email: '', message: '', type: 'query' });
  const [loading, setLoading] = useState(false);
  const [submitStatus, setSubmitStatus] = useState<'idle' | 'success' | 'error'>('idle');
  const [releaseInfo, setReleaseInfo] = useState<ReleaseInfo | null>(null);
  const [loadingRelease, setLoadingRelease] = useState(true);

  useEffect(() => {
    const fetchLatestRelease = async () => {
      try {
        const response = await fetch(GITHUB_API_URL);
        if (response.ok) {
          const data = await response.json();
          const version = data.tag_name.replace('v', '');
          setReleaseInfo({
            version,
            downloadUrl: `https://github.com/tushal-pethani/lakhaan/releases/download/v${version}/billings-windows-v${version}.zip`,
          });
        }
      } catch (error) {
        console.error('Error fetching release:', error);
        setReleaseInfo({
          version: '1.1.9',
          downloadUrl: 'https://github.com/tushal-pethani/lakhaan/releases/latest',
        });
      } finally {
        setLoadingRelease(false);
      }
    };
    fetchLatestRelease();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.message.trim()) return;

    setLoading(true);
    setSubmitStatus('idle');

    try {
      if (typeof window !== 'undefined' && db) {
        await addDoc(collection(db, 'contacts'), {
          name: formData.name || null,
          email: formData.email || null,
          message: formData.message,
          type: formData.type,
          createdAt: serverTimestamp(),
        });
      }
      setSubmitStatus('success');
      setFormData({ name: '', email: '', message: '', type: 'query' });
    } catch (error) {
      console.error('Error submitting form:', error);
      setSubmitStatus('error');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen">
      {/* Header */}
      <header className="fixed top-0 left-0 right-0 z-50 glass border-b border-slate-200 dark:border-slate-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-3">
              <img src="/logo.png" alt="Lakhaan" className="w-10 h-10 object-contain" onError={(e) => { e.currentTarget.style.display = 'none'; }} />
              <span className="text-xl font-bold text-slate-900 dark:text-white">
                Lakhaan
              </span>
            </div>

            <button
              onClick={() => setTheme(resolvedTheme === 'dark' ? 'light' : 'dark')}
              className="p-2 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 transition-colors"
              aria-label="Toggle theme"
            >
              {resolvedTheme === 'dark' ? (
                <svg className="w-5 h-5 text-yellow-500" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clipRule="evenodd" />
                </svg>
              ) : (
                <svg className="w-5 h-5 text-slate-700" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
                </svg>
              )}
            </button>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="pt-32 pb-20 px-4 sm:px-6 lg:px-8 bg-gradient-to-b from-blue-50 to-white dark:from-slate-900 dark:to-slate-900">
        <div className="max-w-4xl mx-auto text-center animate-fade-in">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 text-sm font-medium mb-8">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
            </span>
            100% Free • No Signup Fees • No Subscription
          </div>

          <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-slate-900 dark:text-white mb-6 leading-tight">
            Create GST Invoices for{' '}
            <span className="text-gradient">Free</span> in Seconds
          </h1>

          <p className="text-xl text-slate-600 dark:text-slate-400 mb-10 max-w-2xl mx-auto">
            Simple, fast, and reliable billing software for small businesses — completely free.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <a
              href={releaseInfo?.downloadUrl || GITHUB_REPO_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-center gap-2 px-8 py-4 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-xl transition-all transform hover:scale-105 shadow-lg shadow-blue-600/30"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
              </svg>
              Download Free for Windows {loadingRelease ? '...' : `(v${releaseInfo?.version || 'latest'})`}
            </a>
          </div>

          <div className="mt-6 flex items-center justify-center gap-6 text-sm text-slate-500 dark:text-slate-400">
            <span className="flex items-center gap-1">
              <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
              </svg>
              No payment required
            </span>
            <span className="flex items-center gap-1">
              <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
              </svg>
              ~50MB
            </span>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8 bg-white dark:bg-slate-900">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold text-slate-900 dark:text-white mb-4">
              Everything You Need
            </h2>
            <p className="text-lg text-slate-600 dark:text-slate-400">
              Powerful features to manage your invoicing
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {FEATURES.map((feature, index) => (
              <div
                key={index}
                className="p-6 rounded-2xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 hover:border-blue-500 dark:hover:border-blue-500 transition-all hover:shadow-lg group"
              >
                <div className="text-4xl mb-4">{feature.icon}</div>
                <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-2 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                  {feature.title}
                </h3>
                <p className="text-slate-600 dark:text-slate-400">
                  {feature.desc}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Screenshots Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8 bg-slate-50 dark:bg-slate-800/50">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold text-slate-900 dark:text-white mb-4">
              See It in Action
            </h2>
            <p className="text-lg text-slate-600 dark:text-slate-400">
              Clean and intuitive interface
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            {SCREENSHOTS.map((screenshot, index) => (
              <div
                key={index}
                className="rounded-2xl overflow-hidden shadow-xl hover:shadow-2xl hover:scale-105 transition-all duration-300 group"
              >
                <div className="aspect-video bg-slate-200 dark:bg-slate-700 relative">
                  <img
                    src={screenshot.src}
                    alt={screenshot.alt}
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      e.currentTarget.style.display = 'none';
                      e.currentTarget.parentElement!.innerHTML = `
                        <div class="flex items-center justify-center h-full bg-gradient-to-br from-blue-500 to-purple-600">
                          <div class="text-white text-center">
                            <div class="text-4xl mb-2">📸</div>
                            <p class="font-medium">${screenshot.title}</p>
                            <p class="text-sm opacity-75 mt-1">Add screenshot</p>
                          </div>
                        </div>
                      `;
                    }}
                  />
                </div>
                <div className="p-4 bg-white dark:bg-slate-800 text-center">
                  <p className="font-medium text-slate-900 dark:text-white">{screenshot.title}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Download Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8 bg-gradient-to-r from-blue-600 to-purple-600">
        <div className="max-w-3xl mx-auto text-center">
          <h2 className="text-3xl sm:text-4xl font-bold text-white mb-4">
            Download Lakhaan for Free
          </h2>
          <p className="text-xl text-blue-100 mb-8">
            Version {loadingRelease ? '...' : releaseInfo?.version || 'latest'} • ~50MB • Free forever
          </p>
          <a
            href={releaseInfo?.downloadUrl || GITHUB_REPO_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 px-10 py-5 bg-white text-blue-600 font-bold rounded-xl text-lg hover:bg-blue-50 transition-all transform hover:scale-105 shadow-2xl"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
            </svg>
            Download Now — It's Free
          </a>
          <p className="mt-6 text-blue-100 text-sm">
            No payment required. No hidden charges. No subscription.
          </p>
        </div>
      </section>

      {/* Trust Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8 bg-white dark:bg-slate-900">
        <div className="max-w-4xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold text-slate-900 dark:text-white mb-4">
              Built on Trust
            </h2>
          </div>

          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {TRUST_POINTS.map((point, index) => (
              <div
                key={index}
                className="text-center p-6 rounded-xl bg-slate-50 dark:bg-slate-800"
              >
                <div className="text-3xl mb-3">{point.icon}</div>
                <p className="font-medium text-slate-900 dark:text-white">
                  {point.text}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Contact Section */}
      <section className="py-20 px-4 sm:px-6 lg:px-8 bg-slate-50 dark:bg-slate-800/50">
        <div className="max-w-2xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-3xl sm:text-4xl font-bold text-slate-900 dark:text-white mb-4">
              Contact & Suggestions
            </h2>
            <p className="text-lg text-slate-600 dark:text-slate-400">
              We'd love to hear from you
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="grid sm:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                  Name (optional)
                </label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="w-full px-4 py-3 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                  placeholder="Your name"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                  Email (optional)
                </label>
                <input
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  className="w-full px-4 py-3 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
                  placeholder="your@email.com"
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                Type
              </label>
              <select
                value={formData.type}
                onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                className="w-full px-4 py-3 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all"
              >
                <option value="query">Query</option>
                <option value="suggestion">Suggestion</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                Message *
              </label>
              <textarea
                required
                value={formData.message}
                onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                rows={5}
                className="w-full px-4 py-3 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all resize-none"
                placeholder="Your message..."
              />
            </div>

            <button
              type="submit"
              disabled={loading || !formData.message.trim()}
              className="w-full py-4 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-400 text-white font-semibold rounded-xl transition-all transform hover:scale-105 disabled:hover:scale-100 disabled:cursor-not-allowed"
            >
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                  Sending...
                </span>
              ) : (
                'Send Message'
              )}
            </button>

            {submitStatus === 'success' && (
              <div className="p-4 rounded-xl bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 text-center">
                ✓ Message sent successfully! Thank you for your feedback.
              </div>
            )}

            {submitStatus === 'error' && (
              <div className="p-4 rounded-xl bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400 text-center">
                ✗ Something went wrong. Please try again later.
              </div>
            )}
          </form>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 px-4 sm:px-6 lg:px-8 bg-slate-900 text-white">
        <div className="max-w-6xl mx-auto">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-6">
            <div className="flex items-center gap-3">
              <img src="/logo.png" alt="Lakhaan" className="w-10 h-10 object-contain" onError={(e) => { e.currentTarget.outerHTML = '<div class="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center font-bold text-white">L</div>'; }} />
              <div>
                <p className="font-bold text-lg">Lakhaan</p>
                <p className="text-sm text-slate-400">Free GST Invoice Generator</p>
              </div>
            </div>

            <div className="text-center sm:text-right">
              <p className="text-slate-400">
                Made with ❤️ by <span className="text-white font-medium">Tushal Pethani</span>
              </p>
              <p className="text-sm text-slate-500 mt-1">
                © {new Date().getFullYear()} Lakhaan. All rights reserved.
              </p>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
