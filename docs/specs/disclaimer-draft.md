# ユズリ 免責・法的文言ドラフト v1.0（ja / en）

| 項目 | 内容 |
|---|---|
| 種別 | 法的文言ドラフト（アプリ内表示文＋審査用） |
| 対象 | MVP（ja, en） |
| 連携 | String Catalog のキーとして実装。各カテゴリの `disclaimerKey` から参照（CLAUDE.md §4） |

> **重要（誇張回避・専門性の限界）**：本書は**法的助言ではなく、レビュー前のドラフト**です。特に日本語は弁護士法第72条・税理士法の境界、英語は各国の法制度差に関わるため、**公開前に弁護士等の専門家レビューを必須**とします。英語版は特定の国の法律を断定せず「お住まいの国／法域の専門家へ」という汎用表現に統一しています（確度：中）。

---

## 1. 設計方針

- 本アプリは**情報の記録・整理ツール**。法的・税務的・医療的な「助言」「結論」「代行」は一切行わない。
- 免責は (a) 初回オンボーディング、(b) 書き出し時、(c) 該当カテゴリ画面、で文脈表示する。
- 文言はString Catalogキーで管理し、ロケールごとに差し替える。
- 英語版は法域を断定しない（「in your country / jurisdiction」）。

## 2. キー一覧（String Catalog）

| キー | 表示箇所 |
|---|---|
| `disclaimer.onboarding` | 初回起動 |
| `disclaimer.export` | PDF／アーカイブ書き出し時 |
| `disclaimer.will` | 相続・遺言カテゴリ |
| `disclaimer.tax` | 資産・年金・相続など税務に触れる箇所 |
| `disclaimer.medical` | 医療・介護カテゴリ |
| `disclaimer.sensitive` | 秘匿項目の入力時 |

---

## 3. 文言ドラフト

### 3.1 `disclaimer.onboarding`

**ja**
> ユズリは、あなたの大切な情報を整理して残すための記録ツールです。入力した情報はこの端末内にのみ保存され、外部に送信されることはありません。本アプリは法律・税務・医療に関する専門的な助言を行うものではありません。重要なご判断は、それぞれの専門家にご相談ください。

**en**
> Yuzuri is a tool for organizing and recording the information that matters to you. Everything you enter is stored only on this device and is never sent anywhere. Yuzuri does not provide legal, tax, or medical advice. For important decisions, please consult a qualified professional in your country.

### 3.2 `disclaimer.export`

**ja**
> この書類には、口座やID等の機微な情報が含まれる場合があります。保管場所と共有する相手に十分ご注意ください。なお、この書類は遺言書ではなく、法的な効力はありません。

**en**
> This document may contain sensitive information such as accounts or IDs. Please be careful where you store it and with whom you share it. Note that this document is not a will and has no legal effect.

### 3.3 `disclaimer.will`（相続・遺言）

**ja**
> エンディングノートは遺言書とは異なり、法的な効力はありません。法的に有効な遺言の作成や、相続の手続きについては、弁護士・司法書士などの専門家にご相談ください。本アプリは、法律事務の代行や法的な助言・判断を行うものではありません（弁護士法第72条）。

**en**
> An ending note is not a legally binding will and has no legal effect. For a valid will, or for matters of inheritance and probate, please consult an attorney or other qualified legal professional in your jurisdiction. Yuzuri does not provide legal advice, legal judgments, or legal services.

### 3.4 `disclaimer.tax`（税務に触れる箇所）

**ja**
> 税金や相続税に関する具体的なご判断は、税理士などの専門家にご相談ください。本アプリは、税務相談や税務代理を行うものではありません（税理士法）。

**en**
> For specific questions about taxes, please consult a qualified tax professional. Yuzuri does not provide tax advice or tax services.

### 3.5 `disclaimer.medical`（医療・介護）

**ja**
> ここに記録する内容は、あなたご自身の希望の記録であり、医療上の助言ではありません。治療やケアの方針については、医師など専門職にご相談ください。延命治療や事前の意思表示の法的な取り扱いは、地域によって異なる場合があります。

**en**
> What you record here reflects your own wishes and is not medical advice. Please consult a doctor or other professional regarding treatment and care. The legal status of advance directives or end-of-life wishes may differ depending on where you live.

### 3.6 `disclaimer.sensitive`（秘匿項目入力時）

**ja**
> パスワードや口座番号などの情報そのものを記録すると、漏えいの危険があります。可能な限り「保管場所（どこにあるか）」だけを記録することをおすすめします。記録する場合、その情報はこの端末内で暗号化して保存され、書き出し時は既定で伏せられます。

**en**
> Recording the actual details, such as passwords or account numbers, carries a risk of exposure. Where possible, we recommend recording only where the item is kept. If you do record such details, they are encrypted on this device and are hidden by default when you export.

---

## 4. App Store 審査用メモ（補足）

- アプリ説明文・スクショに「遺言作成」「相続手続き」「医療判断」を**できる**かのような表現を入れない。「希望や情報を整理して記録する」に留める。
- 医療・法律の語を使う箇所には上記免責を併記。
- 【要確認】審査での医療/法律カテゴリ表現の指摘可能性（PRD §16-6）。

## 5. 残課題

- en の「will / executor / power of attorney」等の語が、特定法域の制度を示唆しすぎないか専門家確認。
- 将来のロケール追加時、各国向け免責の作成・レビュー体制（PRD §6.7【要確認】）。
- 日本語の弁護士法72条・税理士法の引用が適切か、弁護士レビューで最終確認。
