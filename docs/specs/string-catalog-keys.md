# ユズリ String Catalog 初期キー表 v1.0（ja / en）

> base全labelKey＋ja差分＋免責＋主要UIキー。`Localizable.xcstrings`（同梱）にそのまま反映済み。
> 翻訳はドラフト。文言は実機で語長・自然さを確認のうえ調整可。

- キー総数：116（カテゴリ20／フィールド68／ja差分4／免責6／UI18）

## カテゴリ

| labelKey | en | ja |
|---|---|---|
| `category.profile` | Basic Information | 基本情報 |
| `category.lifeStory` | Life Story (optional) | 自分史（任意） |
| `category.assets.bank` | Bank Accounts | 預貯金 |
| `category.assets.securities` | Investments & Securities | 有価証券 |
| `category.assets.insurance` | Insurance | 保険 |
| `category.assets.realEstate` | Real Estate | 不動産 |
| `category.assets.cards` | Cards, E-money & Points | カード・電子マネー・ポイント |
| `category.assets.pension` | Pension & Retirement | 年金 |
| `category.assets.liabilities` | Debts & Liabilities | 負債 |
| `category.assets.other` | Other Assets | その他の資産 |
| `category.recurringPayments` | Recurring Payments | 定期支払い |
| `category.digitalLegacy` | Digital Legacy | デジタル遺品 |
| `category.medical` | Medical & Care Wishes | 医療・介護の希望 |
| `category.emergencyCard` | Emergency Card | 緊急医療カード |
| `category.funeral` | Funeral & Burial Wishes | 葬儀・お墓の希望 |
| `category.estatePlanning` | Estate & Will | 相続・遺言 |
| `category.pets` | Pets | ペット |
| `category.contacts` | People to Notify | 連絡してほしい人 |
| `category.messages` | Messages to Loved Ones | 大切な人へのメッセージ |
| `category.documentLocations` | Where Documents Are Kept | 書類のありか |

## 基本情報（profile）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.profile.fullName` | Full name | 氏名 |  |
| `field.profile.dateOfBirth` | Date of birth | 生年月日 |  |
| `field.profile.placeOfBirth` | Place of birth | 出生地 |  |
| `field.profile.bloodType` | Blood type | 血液型 |  |
| `field.profile.nationalIdLocation` | Where ID documents are kept | 身分証の保管場所 |  |
| `field.profile.emergencyContacts` | Emergency contacts | 緊急連絡先 |  |

## 自分史（任意）（lifeStory）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.lifeStory.biography` | Brief life story | 略歴・思い出 |  |
| `field.lifeStory.values` | Values and beliefs to pass on | 伝えたい価値観 |  |

## 預貯金（assets.bank）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.assets.bank.institution` | Bank name | 金融機関名 |  |
| `field.assets.bank.branch` | Branch | 支店 |  |
| `field.assets.bank.accountType` | Account type | 口座種別 |  |
| `field.assets.bank.purpose` | Purpose / notes | 用途・メモ |  |
| `field.assets.bank.accountNumber` | Account number | 口座番号 | 秘匿 |

## 有価証券（assets.securities）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.assets.securities.brokerage` | Brokerage / firm | 証券会社 |  |
| `field.assets.securities.account` | Account reference | 口座情報 |  |
| `field.assets.securities.holdings` | Holdings overview | 保有銘柄の概要 |  |

## 保険（assets.insurance）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.assets.insurance.insurer` | Insurer | 保険会社 |  |
| `field.assets.insurance.policyType` | Policy type | 保険の種類 |  |
| `field.assets.insurance.policyLocation` | Where the policy is kept | 証券の保管場所 |  |
| `field.assets.insurance.beneficiary` | Beneficiary designation | 受取人 |  |

## 不動産（assets.realEstate）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.assets.realEstate.location` | Property location | 所在地 |  |
| `field.assets.realEstate.type` | Property type | 種別 |  |
| `field.assets.realEstate.deedLocation` | Where the deed / title is kept | 権利証の保管場所 |  |

## カード・電子マネー・ポイント（assets.cards）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.assets.cards.creditCards` | Credit / debit cards (issuer, not full number) | クレジット／デビットカード（発行会社） |  |
| `field.assets.cards.eMoney` | E-money / wallets | 電子マネー・ウォレット |  |
| `field.assets.cards.points` | Points / miles | ポイント・マイル |  |

## 年金（assets.pension）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.assets.pension.schemes` | Public / private pension schemes | 公的・私的年金 |  |
| `field.assets.pension.numberLocation` | Where pension / reference numbers are kept | 年金番号の保管場所 |  |
| `field.assets.pension.number` | Pension / reference number | 基礎年金番号 | 秘匿 |

## 負債（assets.liabilities）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.assets.liabilities.lender` | Lender | 借入先 |  |
| `field.assets.liabilities.balance` | Approximate balance | 残高（概算） |  |
| `field.assets.liabilities.guarantees` | Guarantees / co-signed obligations | 連帯保証など |  |

## その他の資産（assets.other）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.assets.other.safeDeposit` | Safe deposit box | 貸金庫 |  |
| `field.assets.other.crypto` | Crypto assets (where access is kept) | 暗号資産（アクセス方法のありか） |  |
| `field.assets.other.valuables` | Valuables / collectibles | 貴金属・コレクション |  |

## 定期支払い（recurringPayments）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.recurringPayments.subscriptions` | Subscriptions to cancel / continue | 解約／継続するサブスク |  |
| `field.recurringPayments.utilities` | Utilities on auto-pay | 自動引き落としの公共料金 |  |
| `field.recurringPayments.memberships` | Memberships / dues | 会費・メンバーシップ |  |

## デジタル遺品（digitalLegacy）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.digitalLegacy.accounts` | Key online accounts | 主要なオンラインアカウント |  |
| `field.digitalLegacy.deviceUnlock` | How to unlock my devices (policy / where kept) | 端末のロック解除方法（方針・ありか） |  |
| `field.digitalLegacy.socialMedia` | What to do with social media / photos | SNS・写真の取り扱い |  |
| `field.digitalLegacy.passwordLocation` | Where passwords are kept | パスワードの保管場所 |  |
| `field.digitalLegacy.passwords` | Passwords (not recommended) | パスワード（記録は非推奨） | 秘匿 |

## 医療・介護の希望（medical）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.medical.conditions` | Conditions | 持病 |  |
| `field.medical.medications` | Medications | 常用薬 |  |
| `field.medical.allergies` | Allergies | アレルギー |  |
| `field.medical.primaryDoctor` | Primary doctor | かかりつけ医 |  |
| `field.medical.advanceDirective` | Living will / advance directive wishes | 延命治療・事前指示の希望 |  |
| `field.medical.organDonation` | Organ donation wishes | 臓器提供の意思 |  |
| `field.medical.careWishes` | Long-term care wishes | 介護の希望 |  |

## 緊急医療カード（emergencyCard）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.emergencyCard.note` | Printable one-page summary of key medical info | 携帯用の医療サマリ |  |

## 葬儀・お墓の希望（funeral）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.funeral.style` | Funeral type / scale | 葬儀の形式・規模 |  |
| `field.funeral.religion` | Religion / customs | 宗教・しきたり |  |
| `field.funeral.notify` | Who to notify | 連絡してほしい人 |  |
| `field.funeral.burial` | Burial / cremation wishes | 埋葬・火葬の希望 |  |

## 相続・遺言（estatePlanning）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.estatePlanning.willExists` | Does a will exist? | 遺言書の有無 |  |
| `field.estatePlanning.willLocation` | Where the will is kept | 遺言書の保管場所 |  |
| `field.estatePlanning.executor` | Executor | 遺言執行者 |  |
| `field.estatePlanning.beneficiaries` | Heirs / beneficiaries | 相続人 |  |
| `field.estatePlanning.poaLocation` | Where power of attorney documents are kept | 委任状・任意後見契約の保管場所 |  |
| `field.estatePlanning.professionals` | Professionals consulted (attorney, etc.) | 相談中の専門家 |  |

## ペット（pets）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.pets.type` | Pet(s) | ペット |  |
| `field.pets.caretaker` | Who will care for them | 世話の引き継ぎ先 |  |
| `field.pets.vet` | Veterinarian | かかりつけ獣医 |  |

## 連絡してほしい人（contacts）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.contacts.notify` | People to notify | 連絡してほしい人 |  |
| `field.contacts.doNotNotify` | People not to notify | 連絡しなくてよい人 |  |

## 大切な人へのメッセージ（messages）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.messages.body` | A message to leave | 遺すメッセージ |  |

## 書類のありか（documentLocations）

| labelKey | en | ja | 備考 |
|---|---|---|---|
| `field.documentLocations.map` | Location of key documents (deeds, policies, IDs, etc.) | 主要書類の保管場所（権利証・証券・身分証など） |  |

## ja差分（JP固有）

| labelKey | en(参考) | ja |
|---|---|---|
| `field.profile.registeredDomicile` | Registered domicile (honseki) | 本籍 |
| `field.funeral.buddhistSect` | Religious sect | 宗派 |
| `field.funeral.kouden` | Condolence money (koden) wishes | 香典の取り扱いの希望 |
| `field.funeral.graveSuccession` | Grave succession | お墓の承継について |

## 免責キー（全文は免責文ドラフト参照）

| key |
|---|
| `disclaimer.onboarding` |
| `disclaimer.export` |
| `disclaimer.will` |
| `disclaimer.tax` |
| `disclaimer.medical` |
| `disclaimer.sensitive` |

## 主要UIキー

| key | en | ja |
|---|---|---|
| `app.name` | Yuzuri | ユズリ |
| `home.title` | Home | ホーム |
| `home.progress` | Completion | 記入率 |
| `home.nextSuggestion` | Suggested next | 次に書くとよい項目 |
| `common.save` | Save | 保存 |
| `common.done` | Done | 完了 |
| `common.cancel` | Cancel | キャンセル |
| `common.delete` | Delete | 削除 |
| `common.notEntered` | Not entered | 未記入 |
| `common.inProgress` | In progress | 記入中 |
| `settings.title` | Settings | 設定 |
| `export.title` | Export | 書き出し |
| `export.safe` | Safe version | 安全版 |
| `export.full` | Full version | 全部入り版 |
| `onboarding.title` | Welcome | ようこそ |
| `paywall.unlock` | Unlock export & backup | 書き出し・バックアップをアンロック |
| `lock.prompt` | Unlock Yuzuri | ユズリのロックを解除 |
| `customItem.add` | Add custom item | カスタム項目を追加 |