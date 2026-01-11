export const ISSUE_TYPE_LABELS: Record<string, string> = {
  'Grammar & Spelling': '語法與拼寫',
  'Definitive Language': '確定性/保證性措辭',
};

export const ISSUE_TYPE_DESCRIPTIONS: Record<string, string> = {
  'Grammar & Spelling': '拼寫、語法與標點等問題（含句式結構）',
  'Definitive Language': '使用過度確定/保證性措辭（如“必須”“一定”“保證”等）',
};

export const ISSUE_STATUS_LABELS: Record<string, string> = {
  not_reviewed: '未處理',
  'not reviewed': '未處理',
  accepted: '已採納',
  dismissed: '已駁回',
}

export type RiskLevel = '高' | '中' | '低'
export type RiskTone = 'danger' | 'warning' | 'success' | 'informative'

export const ISSUE_TYPE_RISK: Record<string, RiskLevel> = {
  'Definitive Language': '高',
  'Grammar & Spelling': '低',
}

export function issueTypeLabel(type: string): string {
  return ISSUE_TYPE_LABELS[type] ?? type;
}

export function issueTypeDescription(type: string): string | undefined {
  return ISSUE_TYPE_DESCRIPTIONS[type];
}

export function normalizeIssueStatus(status: string | undefined): string {
  if (!status) return 'not_reviewed'
  if (status === 'not reviewed') return 'not_reviewed'
  return status
}

export function issueStatusLabel(status: string | undefined): string {
  const normalized = normalizeIssueStatus(status)
  return ISSUE_STATUS_LABELS[normalized] ?? status ?? '未處理'
}

export function issueRiskLevel(type: string, issueRiskLevelValue?: string | null): RiskLevel {
  // 優先使用 issue 自身的 risk_level 字段（自定義規則會設置此值）
  if (issueRiskLevelValue) {
    // 兼容中文和英文值
    if (issueRiskLevelValue === '高' || issueRiskLevelValue === 'high') return '高'
    if (issueRiskLevelValue === '中' || issueRiskLevelValue === 'medium') return '中'
    if (issueRiskLevelValue === '低' || issueRiskLevelValue === 'low') return '低'
  }
  // 回退到基於類型的映射（預設規則）
  return ISSUE_TYPE_RISK[type] ?? '中'
}

export function issueRiskTone(type: string, issueRiskLevelValue?: string | null): RiskTone {
  const level = issueRiskLevel(type, issueRiskLevelValue)
  if (level === '高') return 'danger'
  if (level === '低') return 'success'
  return 'warning'
}
