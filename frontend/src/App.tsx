import { useEffect, useState } from 'react'
import './App.css'

type Connection = 'checking' | 'connected' | 'failed'

const messages: Record<Connection, { title: string; detail: string }> = {
  checking: {
    title: '서버에 연결하고 있어요',
    detail: 'React 화면에서 Spring Boot 서버에 상태를 요청하고 있습니다.',
  },
  connected: {
    title: '서버 연결 성공',
    detail: '화면과 서버가 정상적으로 연결됐어요. 세미콜론의 첫 개발 환경이 준비됐습니다.',
  },
  failed: {
    title: '서버 연결을 확인해 주세요',
    detail: 'Spring Boot 서버를 실행한 뒤 다시 확인해 주세요. 기본 서버 주소는 localhost:8080입니다.',
  },
}

export default function App() {
  const [connection, setConnection] = useState<Connection>('checking')
  const [attempt, setAttempt] = useState(0)

  useEffect(() => {
    const controller = new AbortController()
    let active = true
    const timeout = window.setTimeout(() => controller.abort(), 5_000)

    async function checkConnection() {
      try {
        const response = await fetch('/api/health', { signal: controller.signal })
        if (!response.ok) throw new Error('Health request failed')

        const body: unknown = await response.json()
        if (
          typeof body !== 'object' || body === null ||
          !('status' in body) || body.status !== 'UP' ||
          !('service' in body) || body.service !== 'semicolon-backend'
        ) {
          throw new Error('Unexpected health response')
        }

        if (active) setConnection('connected')
      } catch {
        if (active) setConnection('failed')
      } finally {
        window.clearTimeout(timeout)
      }
    }

    void checkConnection()
    return () => {
      active = false
      window.clearTimeout(timeout)
      controller.abort()
    }
  }, [attempt])

  function retry() {
    setConnection('checking')
    setAttempt((previous) => previous + 1)
  }

  return (
    <div className="page">
      <header className="header">
        <a className="wordmark" href="/" aria-label="세미콜론 홈">semicolon<span>;</span></a>
        <span className="environment">개발 환경 · 초기 세팅</span>
      </header>
      <main>
        <p className="eyebrow">SEMICOLON / START HERE</p>
        <h1>세미콜론의 시작<span>.</span></h1>
        <p className="intro">학회의 일정과 기록, 함께하는 활동을 담을 공간을 준비하고 있어요.</p>
        <section className={`connection ${connection}`} aria-labelledby="connection-title">
          <div className="connection-heading">
            <p className="section-label">첫 번째 연결</p>
            <span className="status"><span className="status-dot" />{connection === 'connected' ? '연결됨' : connection === 'checking' ? '확인 중' : '연결 대기'}</span>
          </div>
          <div role="status" aria-live="polite">
            <h2 id="connection-title">{messages[connection].title}</h2>
            <p>{messages[connection].detail}</p>
          </div>
          <button type="button" onClick={retry} disabled={connection === 'checking'}>
            {connection === 'checking' ? '연결 확인 중…' : '다시 확인하기'}
          </button>
        </section>
        <section className="steps" aria-labelledby="steps-title">
          <h2 id="steps-title">이제 하나씩 만들어가요</h2>
          <ol>
            <li><span className="step-number">01</span><div><h3>기본 구조 준비</h3><p>화면 코드와 서버 코드를 나눠서 관리해요.</p></div></li>
            <li><span className="step-number">02</span><div><h3>기능과 권한 설계</h3><p>회원과 운영진이 할 수 있는 일을 정해요.</p></div></li>
            <li><span className="step-number">03</span><div><h3>화면과 데이터 연결</h3><p>일정부터 시작해서 기능을 하나씩 완성해요.</p></div></li>
          </ol>
        </section>
      </main>
      <footer>semicolon; · 학회 홈페이지 개발의 첫 단계</footer>
    </div>
  )
}
