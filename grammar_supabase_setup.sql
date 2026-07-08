-- ============================================================
-- 문법과제 프로젝트 (Grammar Zone 중등필수) 스키마
-- 기존 students / student_pins / student_pin_verify 재사용
-- Supabase SQL Editor에서 한 번만 실행
-- ============================================================

-- 1) 유닛 목록
create table if not exists grammar_units (
  unit_no int primary key,
  chapter text not null,
  title   text not null
);

-- 2) 문제 은행
create table if not exists grammar_questions (
  id serial primary key,
  unit_no int not null references grammar_units(unit_no),
  level int not null check (level in (1,2,3)),   -- 1=중3, 2=고1·2, 3=고3+
  qtype text not null,
  stem text not null,
  choices jsonb not null,
  answer int not null check (answer between 1 and 5),
  explanation text not null,
  active boolean not null default true
);
create index if not exists gq_unit_idx on grammar_questions(unit_no);

-- 3) 시험지 (진도 이벤트 = 시험지 1장)
create table if not exists grammar_tests (
  id serial primary key,
  label text not null,
  unit_from int not null references grammar_units(unit_no),
  unit_to   int not null references grammar_units(unit_no),
  question_ids jsonb not null,          -- 출제 문항 id 배열 (고정)
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- 4) 응시 기록
create table if not exists grammar_attempts (
  id serial primary key,
  student_id uuid not null references students(id),
  test_id int not null references grammar_tests(id),
  score int not null,
  total int not null,
  duration_sec int,
  taken_at timestamptz not null default now()
);
create index if not exists ga_student_idx on grammar_attempts(student_id);
create index if not exists ga_test_idx on grammar_attempts(test_id);

-- 5) 문항별 응답
create table if not exists grammar_attempt_items (
  id serial primary key,
  attempt_id int not null references grammar_attempts(id) on delete cascade,
  question_id int not null references grammar_questions(id),
  unit_no int not null,
  level int not null,
  answer int,               -- null = 무응답
  correct boolean not null,
  seq int not null
);
create index if not exists gai_attempt_idx on grammar_attempt_items(attempt_id);

-- RLS (미니모의고사와 동일한 소규모 운영 전제)
alter table grammar_units enable row level security;
alter table grammar_questions enable row level security;
alter table grammar_tests enable row level security;
alter table grammar_attempts enable row level security;
alter table grammar_attempt_items enable row level security;

drop policy if exists gu_read on grammar_units;
create policy gu_read on grammar_units for select using (true);

drop policy if exists gq_read on grammar_questions;
create policy gq_read on grammar_questions for select using (true);

drop policy if exists gt_read on grammar_tests;
create policy gt_read on grammar_tests for select using (true);
drop policy if exists gt_write on grammar_tests;
create policy gt_write on grammar_tests for insert with check (true);
drop policy if exists gt_update on grammar_tests;
create policy gt_update on grammar_tests for update using (true);

drop policy if exists ga_read on grammar_attempts;
create policy ga_read on grammar_attempts for select using (true);
drop policy if exists ga_write on grammar_attempts;
create policy ga_write on grammar_attempts for insert with check (true);

drop policy if exists gai_read on grammar_attempt_items;
create policy gai_read on grammar_attempt_items for select using (true);
drop policy if exists gai_write on grammar_attempt_items;
create policy gai_write on grammar_attempt_items for insert with check (true);

-- Realtime (선생님 대시보드 실시간 탭)
do $$ begin
  alter publication supabase_realtime add table grammar_attempts;
exception when duplicate_object then null; end $$;

-- 유닛 목록 시드
insert into grammar_units (unit_no, chapter, title) values
 (1,'문장의 기초','품사, 구와 절'),
 (2,'문장의 기초','문장성분'),
 (3,'문장의 기초','문장의 형식 I (1·3·4형식)'),
 (4,'문장의 기초','문장의 형식 II (2·5형식)'),
 (5,'문장의 기초','여러 가지 문장 I (be동사와 일반동사)'),
 (6,'문장의 기초','여러 가지 문장 II (의문사 의문문·명령문·감탄문)'),
 (7,'명사·관사·대명사','명사'),
 (8,'명사·관사·대명사','관사'),
 (9,'명사·관사·대명사','대명사의 개념, 지시·재귀대명사'),
 (10,'명사·관사·대명사','it의 다양한 쓰임, one·another·other'),
 (11,'명사·관사·대명사','그 외 대명사 (some/any, all/each/none, both/neither/either)'),
 (12,'형용사·부사·전치사','형용사'),
 (13,'형용사·부사·전치사','부사'),
 (14,'형용사·부사·전치사','비교 I (형태, 비교급)'),
 (15,'형용사·부사·전치사','비교 II (원급, 최상급)'),
 (16,'형용사·부사·전치사','장소를 나타내는 전치사'),
 (17,'형용사·부사·전치사','시간을 나타내는 전치사, 기타 전치사'),
 (18,'시제·조동사·수동태','시제의 개념, 현재시제, 과거시제'),
 (19,'시제·조동사·수동태','미래시제'),
 (20,'시제·조동사·수동태','진행형'),
 (21,'시제·조동사·수동태','현재완료형'),
 (22,'시제·조동사·수동태','현재완료 진행형, 과거완료형'),
 (23,'시제·조동사·수동태','조동사의 개념, 능력·추측·가능성의 조동사'),
 (24,'시제·조동사·수동태','허가·요청·의무·충고의 조동사'),
 (25,'시제·조동사·수동태','습관·상태의 조동사, 조동사+have v-ed'),
 (26,'시제·조동사·수동태','수동태의 개념 및 형태'),
 (27,'시제·조동사·수동태','주의해야 할 수동태'),
 (28,'to부정사·동명사·분사','to부정사의 기초, 명사처럼 쓰이는 to부정사'),
 (29,'to부정사·동명사·분사','형용사·부사처럼 쓰이는 to부정사'),
 (30,'to부정사·동명사·분사','to부정사의 의미상 주어, 자주 쓰이는 표현'),
 (31,'to부정사·동명사·분사','목적격 보어로 쓰이는 부정사'),
 (32,'to부정사·동명사·분사','동명사의 기초'),
 (33,'to부정사·동명사·분사','동명사 vs. to부정사'),
 (34,'to부정사·동명사·분사','자주 쓰이는 동명사 구문'),
 (35,'to부정사·동명사·분사','분사의 개념 및 역할'),
 (36,'to부정사·동명사·분사','현재분사 vs. 과거분사'),
 (37,'to부정사·동명사·분사','분사구문'),
 (38,'접속사·관계사','접속사의 기본 개념, 등위접속사'),
 (39,'접속사·관계사','종속접속사 (that, whether, if), 간접의문문'),
 (40,'접속사·관계사','부사절을 이끄는 종속접속사'),
 (41,'접속사·관계사','관계대명사의 역할, 주격 관계대명사'),
 (42,'접속사·관계사','목적격·소유격 관계대명사, what'),
 (43,'접속사·관계사','관계부사'),
 (44,'접속사·관계사','관계사의 계속적 용법'),
 (45,'가정법·일치','가정법 과거, 가정법 과거완료'),
 (46,'가정법·일치','일치')
on conflict (unit_no) do update set chapter=excluded.chapter, title=excluded.title;
-- 문제은행 시드 (230문제) — 주의: 기존 grammar_* 데이터 초기화 후 삽입
delete from grammar_attempt_items; delete from grammar_attempts; delete from grammar_tests; delete from grammar_questions;
insert into grammar_questions (unit_no, level, qtype, stem, choices, answer, explanation) values
(1,1,'품사 판단','다음 문장에서 밑줄 친 단어의 품사로 알맞은 것은?

The <u>kind</u> woman helped us.','["명사", "동사", "형용사", "부사", "대명사"]'::jsonb,3,'kind는 뒤에 오는 명사 woman을 꾸며 주므로 형용사이다. 명사 앞에서 명사를 수식하는 말은 형용사이며, 동사(helped)를 꾸미는 부사와 혼동하지 않도록 주의한다.'),
(1,1,'품사 판단','다음 중 품사가 부사인 것은?','["happy", "happiness", "happen", "happily", "happier"]'::jsonb,4,'happily는 ''행복하게''라는 뜻으로 동사를 꾸며 주는 부사이다. happy는 형용사, happiness는 명사, happen은 동사, happier는 형용사 happy의 비교급 형태이므로 부사가 아니다.'),
(1,2,'구와 절 구분','다음 중 절(clause)에 해당하는 것은?','["in the morning", "because it rained", "very quickly", "to play soccer", "playing the piano"]'::jsonb,2,'절은 ''주어 + 동사''를 갖춘 단어 덩어리인데, because it rained에는 주어 it과 동사 rained가 있으므로 절이다. 나머지는 모두 주어와 동사를 갖추지 못한 구(phrase)이며, to play soccer나 playing the piano처럼 동사의 형태가 들어 있어도 주어가 없으면 절이 아니다.'),
(1,2,'품사 비교','다음 중 밑줄 친 단어의 품사가 나머지 넷과 <b>다른</b> 것은?','["She gave me a <u>present</u> on my birthday.", "I need a glass of <u>water</u>.", "He bought a new <u>watch</u> last week.", "They <u>plant</u> trees every spring.", "The <u>answer</u> to the question was wrong."]'::jsonb,4,'④의 plant는 주어 They 뒤에서 ''심는다''라는 동작을 나타내므로 동사이다. 나머지 present, water, watch, answer는 모두 문장 안에서 사물의 이름을 나타내는 명사로 쓰였으며, 같은 철자라도 문장 속 역할에 따라 품사가 달라진다는 점에 주의한다.'),
(1,3,'밑줄 어법','다음 글의 밑줄 친 부분 중 어법상 <b>틀린</b> 것은?

My grandmother lives <u>happily</u>① in a small village. She grows <u>fresh</u>② vegetables and shares them with her <u>friendly</u>③ neighbors. Everyone says her garden is <u>wonderful</u>④, and she takes care of it very <u>careful</u>⑤.','["happily", "fresh", "friendly", "wonderful", "careful"]'::jsonb,5,'⑤는 동사구 takes care of를 꾸며야 하므로 형용사 careful이 아니라 부사 carefully가 되어야 한다. ③ friendly는 -ly로 끝나지만 명사 neighbors를 꾸미는 형용사로 올바르게 쓰였고, ①의 happily는 동사 lives를 꾸미는 부사로 적절하다.'),
(2,1,'문장성분 찾기','다음 문장에서 주어에 해당하는 것은?

The tall boy in the classroom is my brother.','["The tall boy", "the classroom", "is", "my brother", "tall"]'::jsonb,1,'문장의 주어는 동사 is 앞에서 ''~은/는''에 해당하는 The tall boy이다. in the classroom은 주어를 꾸며 주는 수식어구이고, my brother는 주어를 보충 설명하는 보어이므로 주어가 아니다.'),
(2,1,'문장성분 찾기','다음 문장에서 목적어에 해당하는 것은?

Kevin bought a new bike yesterday.','["Kevin", "bought", "a new bike", "yesterday", "new"]'::jsonb,3,'동사 bought의 대상이 되는 ''~을/를''에 해당하는 a new bike가 목적어이다. yesterday는 때를 나타내는 수식어이므로 문장의 필수 성분이 아니고, new는 bike를 꾸미는 형용사일 뿐 단독으로 목적어가 될 수 없다.'),
(2,2,'문장성분 비교','다음 중 밑줄 친 부분의 문장성분이 나머지 넷과 <b>다른</b> 것은?','["She became <u>a doctor</u> last year.", "He is <u>my best friend</u>.", "The soup smells <u>delicious</u>.", "They finally found <u>the key</u>.", "His voice sounds <u>strange</u> today."]'::jsonb,4,'④의 the key는 동사 found의 대상이 되는 목적어이다. 나머지는 모두 become, be, smell, sound와 같은 동사 뒤에서 주어의 상태나 신분을 보충 설명하는 주격 보어이며, ''주어 = 밑줄 부분''의 관계가 성립하는지로 보어와 목적어를 구분할 수 있다.'),
(2,2,'수식어 판단','다음 중 밑줄 친 부분이 문장의 필수 성분이 아닌 <b>수식어</b>인 것은?','["I really like <u>this song</u>.", "She is <u>a nurse</u> at the hospital.", "He runs <u>in the park</u> every morning.", "We need <u>your help</u> right now.", "They are <u>middle school students</u>."]'::jsonb,3,'③의 in the park는 장소를 나타내는 수식어구로, 빼도 He runs라는 완전한 문장이 성립한다. ①과 ④의 밑줄 부분은 목적어, ②와 ⑤는 보어로 모두 문장의 필수 성분이므로 생략하면 문장이 불완전해진다.'),
(2,3,'밑줄 어법','다음 글의 밑줄 친 부분 중 어법상 <b>틀린</b> 것은?

Julia is a <u>famous</u>① writer. Her novels <u>are</u>② popular among teenagers, and her stories always make readers <u>happy</u>③. Last year she <u>wrote</u>④ a new book, and it became a big <u>successfully</u>⑤.','["famous", "are", "happy", "wrote", "successfully"]'::jsonb,5,'⑤는 동사 became 뒤에서 주어 it을 보충 설명하는 보어 자리이고 앞에 관사 a big이 있으므로 부사 successfully가 아니라 명사 success가 되어야 한다. ③의 happy는 make의 목적어 readers의 상태를 설명하는 보어 자리이므로 형용사가 올바르다.'),
(3,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

My uncle gave ___ a nice camera on my birthday.','["to me", "me", "for me", "mine", "I"]'::jsonb,2,'give가 4형식으로 쓰이면 ''give + 간접목적어 + 직접목적어'' 순서이므로 목적격 me가 알맞다. to me는 3형식(gave a nice camera to me)에서 쓰는 형태이며, 4형식 어순에서는 전치사 없이 목적격만 온다.'),
(3,1,'문장 형식 판단','다음 문장의 형식으로 알맞은 것은?

The sun rises in the east.','["1형식", "2형식", "3형식", "4형식", "5형식"]'::jsonb,1,'rises는 목적어나 보어가 필요 없는 완전자동사이므로 ''주어 + 동사''만으로 문장이 성립하는 1형식이다. in the east는 장소를 나타내는 수식어구일 뿐 문장의 필수 성분이 아니므로 형식에 포함되지 않는다.'),
(3,2,'문장 전환','다음 두 문장의 의미가 같도록 빈칸에 들어갈 말로 알맞은 것은?

She made her son a sandwich. = She made a sandwich ___ her son.','["to", "for", "of", "at", "with"]'::jsonb,2,'make, buy, cook처럼 ''~을 위해 만들어 주다''라는 의미의 동사는 4형식을 3형식으로 바꿀 때 전치사 for를 쓴다. to는 give, send, tell 등에 쓰고 of는 ask에 쓰므로 동사에 따라 전치사를 구분해야 한다.'),
(3,2,'어법 판단','다음 중 어법상 <b>틀린</b> 문장은?','["He sent me an email this morning.", "My mom bought a scarf for me.", "She asked a question of the teacher.", "I explained him the rule.", "The train arrived at noon."]'::jsonb,4,'explain은 4형식으로 쓸 수 없는 동사이므로 I explained the rule to him.처럼 3형식으로 써야 한다. ③의 ask는 3형식 전환 시 전치사 of를 쓰는 동사이므로 올바른 문장이며, ②의 buy는 for를 쓰는 것이 맞다.'),
(3,3,'밑줄 어법','다음 글의 밑줄 친 부분 중 어법상 <b>틀린</b> 것은?

Last weekend, my family <u>visited</u>① my grandparents. Grandma <u>cooked us</u>② a delicious dinner, and Grandpa <u>told</u>③ us funny stories. Before we left, I <u>gave a small gift for</u>④ Grandma, and she <u>smiled</u>⑤ warmly.','["visited", "cooked us", "told", "gave a small gift for", "smiled"]'::jsonb,4,'give를 3형식으로 쓸 때는 ''give + 직접목적어 + to + 사람''이므로 gave a small gift to Grandma가 되어야 한다. ②의 cook은 4형식 ''cook + 사람 + 음식''으로 쓸 수 있어 올바르고, ⑤의 smiled는 1형식 자동사로 뒤에 부사 warmly가 오는 것이 자연스럽다.'),
(4,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

This cake tastes really ___.','["sweetly", "sweet", "sweetness", "to sweet", "sweeten"]'::jsonb,2,'taste, smell, look 같은 감각동사 뒤에는 주어의 상태를 설명하는 형용사 보어가 온다. ''~하게''로 해석된다고 해서 부사 sweetly를 쓰면 틀리며, 이는 2형식 문장에서 가장 흔한 실수이다.'),
(4,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

The news made everyone ___.','["happily", "happiness", "happy", "to happy", "be happily"]'::jsonb,3,'''make + 목적어 + 목적격 보어''의 5형식 구조로, 목적어 everyone의 상태를 설명하는 형용사 happy가 알맞다. 목적격 보어 자리에 부사 happily를 쓰는 것은 한국 학생들이 자주 하는 실수이므로 주의한다.'),
(4,2,'어법 판단','다음 중 어법상 <b>옳은</b> 문장은?','["The music sounds beautifully.", "She kept the window opening all day.", "I found the movie boring.", "He made his son to clean the room.", "Her voice seems nervously."]'::jsonb,3,'''find + 목적어 + 목적격 보어'' 구조에서 영화가 지루한 감정을 일으키는 주체이므로 boring이 올바르다. ①과 ⑤는 감각동사·seem 뒤에 형용사가 와야 하므로 틀렸고, ④는 사역동사 make 뒤에 동사원형 clean이 와야 하며, ②는 keep the window open처럼 형용사 보어를 써야 한다.'),
(4,2,'영작','다음 우리말을 영어로 바르게 옮긴 것은?

그 선생님은 우리에게 매일 일기를 쓰게 하셨다.','["The teacher made us keep a diary every day.", "The teacher made us to keep a diary every day.", "The teacher made us keeping a diary every day.", "The teacher made us kept a diary every day.", "The teacher made to us keep a diary every day."]'::jsonb,1,'사역동사 make는 ''(make + 목적어 + 동사원형)''의 5형식으로 쓰므로 made us keep이 올바르다. ②처럼 to부정사를 쓰거나 ③처럼 -ing형을 쓰는 것은 사역동사 구문에서 흔히 나오는 오답 유형이다.'),
(4,3,'밑줄 어법','다음 글의 밑줄 친 부분 중 어법상 <b>틀린</b> 것은?

Mr. Han is a strict but <u>warm</u>① teacher. He always keeps his classroom <u>clean</u>②, and he never lets students <u>use</u>③ their phones in class. His lessons sometimes look <u>difficult</u>④, but they make learning <u>enjoyably</u>⑤.','["warm", "clean", "use", "difficult", "enjoyably"]'::jsonb,5,'⑤는 ''make + 목적어(learning) + 목적격 보어'' 구조이므로 부사 enjoyably가 아니라 형용사 enjoyable이 되어야 한다. ②의 clean은 keep의 목적격 보어인 형용사로 올바르고, ③은 사역동사 let 뒤의 동사원형이므로 적절하다.'),
(5,1,'빈칸','다음 대화의 빈칸에 들어갈 말로 가장 적절한 것은?

A: ___ your sister like Korean food?
B: Yes, she does.','["Do", "Does", "Is", "Are", "Did"]'::jsonb,2,'주어 your sister가 3인칭 단수이고 대답이 she does이므로 현재시제 의문문을 만드는 Does가 알맞다. 일반동사 like가 있으므로 be동사 Is를 쓸 수 없고, 대답이 does이므로 과거형 Did도 답이 될 수 없다.'),
(5,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

He ___ busy yesterday, so he watched TV all day.','["isn''t", "wasn''t", "doesn''t", "didn''t", "aren''t"]'::jsonb,2,'busy는 형용사이므로 be동사가 필요하고, yesterday가 있으므로 과거형 부정 wasn''t가 알맞다. 일반동사 부정에 쓰는 doesn''t/didn''t는 형용사 앞에 올 수 없으며, isn''t는 현재시제라서 yesterday와 맞지 않는다.'),
(5,2,'어법 판단','다음 중 어법상 <b>틀린</b> 문장은?','["She doesn''t eat breakfast on weekdays.", "Are they middle school students?", "He didn''t watched the movie last night.", "I am not good at math.", "Does Tom play the guitar well?"]'::jsonb,3,'didn''t 뒤에는 동사원형이 와야 하므로 didn''t watch가 되어야 한다. 조동사 do/does/did가 시제와 수를 나타내면 뒤의 동사는 항상 원형으로 쓰는 것이 원칙이며, 나머지 문장은 모두 어법에 맞다.'),
(5,2,'대화 빈칸','다음 대화의 빈칸 (A), (B)에 들어갈 말이 순서대로 바르게 짝지어진 것은?

A: (A) you at the library yesterday afternoon?
B: No, I (B). I was at home all day.','["Were - wasn''t", "Did - didn''t", "Were - weren''t", "Was - wasn''t", "Are - am not"]'::jsonb,1,'at the library라는 장소 표현 앞에는 be동사가 필요하고 주어가 you이므로 과거형 Were가, 대답의 주어는 I이므로 wasn''t가 알맞다. ③은 I 뒤에 weren''t를 쓸 수 없어서 틀리고, ②는 문장에 일반동사가 없으므로 Did를 쓸 수 없다.'),
(5,3,'밑줄 어법','다음 글의 밑줄 친 부분 중 어법상 <b>틀린</b> 것은?

My brother <u>doesn''t like</u>① getting up early, so he <u>is</u>② often late for school. Yesterday he <u>missed</u>③ the bus again. Mom asked, "Why <u>didn''t you set</u>④ your alarm?" He answered, "I set it, but I <u>wasn''t hear</u>⑤ it."','["doesn''t like", "is", "missed", "didn''t you set", "wasn''t hear"]'::jsonb,5,'hear는 일반동사이므로 과거 부정은 be동사가 아니라 didn''t hear로 써야 한다. be동사의 부정(wasn''t)과 일반동사의 부정(didn''t + 동사원형)을 섞어 쓰는 것은 대표적인 오류이며, ④는 의문사가 있는 일반동사 과거 의문문으로 올바른 형태이다.'),
(6,1,'빈칸','다음 대화의 빈칸에 들어갈 말로 가장 적절한 것은?

A: ___ is your birthday?
B: It''s May 5th.','["Who", "What", "When", "Where", "How"]'::jsonb,3,'대답이 May 5th라는 날짜이므로 ''언제''를 묻는 의문사 When이 알맞다. What은 사물이나 정체를, Where는 장소를 물을 때 쓰므로 대답과 어울리지 않는다.'),
(6,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

___ quiet in the library, please.','["Be", "Is", "Are", "Being", "To be"]'::jsonb,1,'명령문은 주어 You를 생략하고 동사원형으로 시작하므로 be동사의 원형인 Be가 알맞다. Is나 Are 같은 be동사의 변화형이나 Being, To be는 명령문의 첫머리에 쓸 수 없다.'),
(6,2,'어법 판단','다음 중 어법상 <b>옳은</b> 문장은?','["What a beautiful flowers they are!", "How tall he is!", "What kind she is!", "How a smart boy he is!", "What delicious the pizza is!"]'::jsonb,2,'''How + 형용사 + 주어 + 동사!'' 어순이므로 How tall he is!는 올바른 감탄문이다. ①은 복수명사 flowers 앞에 a를 쓸 수 없고, ③과 ⑤는 형용사만 강조하므로 How를 써야 하며, ④는 명사를 포함하므로 What a smart boy he is!가 되어야 한다.'),
(6,2,'영작','다음 우리말을 영어로 바르게 옮긴 것은?

그녀는 왜 어제 학교에 오지 않았니?','["Why she didn''t come to school yesterday?", "Why didn''t she come to school yesterday?", "Why doesn''t she came to school yesterday?", "Why didn''t she came to school yesterday?", "Why did she not comes to school yesterday?"]'::jsonb,2,'의문사가 있는 의문문은 ''의문사 + 조동사 + 주어 + 동사원형'' 어순이므로 Why didn''t she come ~?이 올바르다. ①은 주어와 조동사가 도치되지 않아 틀렸고, ④는 didn''t 뒤에 과거형 came을 써서 틀렸다.'),
(6,3,'밑줄 어법','다음 글의 밑줄 친 부분 중 어법상 <b>틀린</b> 것은?

<u>What</u>① a wonderful day it was! We went hiking, and the view from the top was amazing. "Look at that lake! <u>How beautiful</u>② it is!" my sister shouted. "<u>Don''t stand</u>③ too close to the edge," Dad warned us. On the way home, Mom asked, "<u>How often</u>④ do you want to come here?" "Every month! <u>Doesn''t miss</u>⑤ a chance like this," I said.','["What", "How beautiful", "Don''t stand", "How often", "Doesn''t miss"]'::jsonb,5,'부정 명령문은 ''Don''t + 동사원형''으로 시작하므로 Doesn''t miss가 아니라 Don''t miss가 되어야 한다. ①은 ''What + a + 형용사 + 명사'' 어순의 올바른 감탄문이고, ③은 부정 명령문의 올바른 형태이다.'),
(7,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

She bought two ___ of bread at the bakery.','["loaf", "loafs", "loaves", "breads", "loave"]'::jsonb,3,'bread는 셀 수 없는 명사이므로 loaf 같은 단위 명사를 이용해 세고, two 뒤이므로 복수형이 필요하다. loaf처럼 -f로 끝나는 명사는 -ves로 복수형을 만들므로 loaves가 정답이며, loafs나 breads처럼 쓰는 것은 틀리다.'),
(7,1,'어법','다음 중 명사의 복수형이 잘못 연결된 것은?','["leaf – leaves", "city – cities", "tooth – teeth", "potato – potatos", "woman – women"]'::jsonb,4,'자음+o로 끝나는 potato는 -es를 붙여 potatoes로 복수형을 만들므로 potatos는 틀리다. leaf-leaves, city-cities는 규칙 변화이고 tooth-teeth, woman-women은 올바른 불규칙 변화이다.'),
(7,2,'어법','다음 중 어법상 옳은 문장은?','["He gave me some good advices about my future.", "I need to buy two pieces of furnitures for my room.", "She drank a glass of milk before going to bed.", "There is many informations on the school website.", "He bought three breads at the store this morning."]'::jsonb,3,'milk는 셀 수 없는 명사이므로 a glass of milk처럼 단위 표현으로 나타낸 ③이 옳다. advice, furniture, information, bread는 모두 셀 수 없는 명사여서 복수형(advices, furnitures 등)으로 쓸 수 없고, ④는 many 대신 much를 써야 한다.'),
(7,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

The police ___ investigating the mysterious case now.','["is", "are", "was", "has been", "be"]'::jsonb,2,'police는 형태는 단수처럼 보이지만 항상 복수 취급하는 명사이므로 복수동사 are가 와야 한다. 또한 now가 있어 현재진행형이 자연스러우므로 과거형 was나 has been은 시제상으로도 어색하다.'),
(7,3,'밑줄','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

Last weekend, my family visited a small farm. The farmer showed us many <u>sheep</u>① and gave us fresh <u>milk</u>②. My brother took several <u>photos</u>③ of the animals. We also learned that the farmer had sold most of his <u>furnitures</u>④ to build a new barn. It was one of the most memorable <u>experiences</u>⑤ of my life.','["① sheep", "② milk", "③ photos", "④ furnitures", "⑤ experiences"]'::jsonb,4,'furniture는 셀 수 없는 명사이므로 복수형 furnitures로 쓸 수 없고 furniture로 써야 한다. sheep은 단수와 복수의 형태가 같은 명사이고, milk는 셀 수 없는 명사로 그대로 쓰며, photos와 experiences는 올바른 복수형이다.'),
(8,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

He is ___ honest student, so everyone trusts him.','["a", "an", "the", "some", "any"]'::jsonb,2,'honest는 철자는 h로 시작하지만 발음이 모음([ɑ])으로 시작하므로 an을 쓴다. 관사는 철자가 아니라 발음을 기준으로 a/an을 선택한다는 점에 주의해야 한다.'),
(8,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

I bought a book yesterday. ___ book was really interesting.','["A", "An", "The", "Some", "Any"]'::jsonb,3,'앞 문장에서 이미 언급된 명사를 다시 가리킬 때는 정관사 The를 쓴다. A/An은 처음 언급하는 불특정한 대상에 쓰이므로 여기서는 알맞지 않다.'),
(8,2,'어법','다음 중 어법상 틀린 문장은?','["We usually have lunch at noon.", "She goes to school by bus every morning.", "He plays the piano very well.", "They play the soccer every Sunday afternoon.", "The sun rises in the east."]'::jsonb,4,'운동 경기 이름 앞에는 관사를 쓰지 않으므로 play soccer가 되어야 한다. 반면 악기 이름 앞에는 the를 쓰고(play the piano), 식사 이름(lunch)과 ''by+교통수단''에는 관사를 생략하며, 세상에 하나뿐인 것(the sun, the east)에는 the를 쓴다.'),
(8,2,'빈칸','다음 빈칸 (A), (B)에 들어갈 말이 순서대로 바르게 짝지어진 것은?

She plays (A) violin every evening, and her brother plays (B) basketball with his friends.','["the – the", "a – the", "the – (관사 없음)", "a – (관사 없음)", "(관사 없음) – the"]'::jsonb,3,'악기 이름 앞에는 정관사 the를 쓰므로 (A)는 the violin이 맞다. 반면 운동 경기 이름 앞에는 관사를 쓰지 않으므로 (B)는 관사 없이 basketball로 써야 한다.'),
(8,3,'밑줄','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

Jane goes to <u>school</u>① by subway every day. After school, she practices <u>the</u>② cello for an hour. Yesterday, she watched <u>a</u>③ movie with her friends, and <u>the</u>④ movie was about a musician. She wants to become <u>the</u>⑤ world-famous cellist someday.','["① school", "② the", "③ a", "④ the", "⑤ the"]'::jsonb,5,'''세계적으로 유명한 첼리스트 한 명''이 되고 싶다는 뜻이므로 불특정한 대상을 나타내는 a world-famous cellist로 써야 한다. ①은 ''go to school(학교에 다니다)''로 관사를 생략하는 표현이고, ②는 악기 앞의 the, ③④는 처음 언급할 때 a, 다시 언급할 때 the를 쓴 올바른 용법이다.'),
(9,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

This bag is not mine; it is ___.','["her", "hers", "she", "herself", "their"]'::jsonb,2,'''그녀의 것''이라는 의미의 소유대명사가 필요하므로 hers가 정답이다. her는 소유격 또는 목적격이어서 뒤에 명사가 없으면 단독으로 쓸 수 없고, herself는 재귀대명사이므로 어울리지 않는다.'),
(9,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

___ are my classmates standing over there.','["This", "That", "These", "Those", "It"]'::jsonb,4,'over there(저기)로 보아 멀리 있는 대상을 가리키고, classmates가 복수이며 동사도 are이므로 복수 지시대명사 Those가 알맞다. This/That은 단수이고 These는 가까운 대상을 가리키므로 틀리다.'),
(9,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

The little girl is now old enough to dress ___ in the morning.','["her", "hers", "herself", "she", "itself"]'::jsonb,3,'주어(The little girl)와 목적어가 같은 대상이므로 재귀대명사 herself를 써서 ''스스로 옷을 입다''라는 뜻을 나타낸다. her를 쓰면 자신이 아닌 다른 여자에게 옷을 입힌다는 의미가 되어 문맥에 맞지 않는다.'),
(9,2,'밑줄','다음 중 밑줄 친 재귀대명사를 생략할 수 있는 것은?','["She looked at <u>herself</u> in the mirror.", "He fixed the computer <u>himself</u>.", "The cat hurt <u>itself</u> while jumping down.", "Please help <u>yourself</u> to the cookies.", "They enjoyed <u>themselves</u> at the party."]'::jsonb,2,'②의 himself는 주어를 강조하는 강조 용법으로 쓰였으므로 생략해도 문장이 성립한다. ①③은 동사·전치사의 목적어로 쓰인 재귀 용법이라 생략할 수 없고, ④ help yourself(마음껏 먹다)와 ⑤ enjoy oneself(즐겁게 보내다)는 관용 표현이라 생략할 수 없다.'),
(9,3,'밑줄','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

When Tom moved to a new city, he had to do everything by <u>himself</u>①. The weather of the new city was much colder than <u>that</u>② of his hometown. At first, he often talked to <u>himself</u>③ because he had no friends. But soon he met people whose hobbies were similar to <u>him</u>④, and they introduced <u>themselves</u>⑤ to one another.','["① himself", "② that", "③ himself", "④ him", "⑤ themselves"]'::jsonb,4,'비교 대상은 사람들의 취미와 ''그의 취미(his hobbies)''이므로 목적격 him이 아니라 소유대명사 his를 써야 한다. ②의 that은 앞의 the weather를 대신하는 지시대명사이고, ①③⑤의 재귀대명사는 각각 관용·재귀 용법으로 올바르게 쓰였다.'),
(10,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

___ is raining outside, so take your umbrella.','["This", "That", "It", "There", "One"]'::jsonb,3,'날씨를 나타낼 때는 비인칭 주어 It을 쓴다. 이때 It은 ''그것''이라고 해석하지 않으며, This나 That 같은 지시대명사는 날씨 표현의 주어로 쓸 수 없다.'),
(10,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

I left my pen at home. Can I borrow ___?','["it", "one", "another", "other", "the other"]'::jsonb,2,'정해지지 않은 ''아무 펜 하나''를 빌리려는 것이므로 같은 종류의 불특정한 물건을 가리키는 one이 알맞다. it은 집에 두고 온 바로 그 펜을 가리키므로 빌린다는 문맥에 맞지 않는다.'),
(10,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

She has three caps. One is red, another is blue, and ___ is green.','["other", "others", "the others", "the other", "another"]'::jsonb,4,'셋 중 하나는 one, 또 다른 하나는 another, 마지막 남은 하나는 정해져 있으므로 the other로 나타낸다. others나 the others는 복수를 가리키므로 남은 하나를 나타낼 수 없고, other는 단독으로 주어가 될 수 없다.'),
(10,2,'밑줄','다음 중 밑줄 친 It[it]의 쓰임이 나머지 넷과 <b>다른</b> 것은?','["<u>It</u> is getting dark outside.", "<u>It</u> is five kilometers from here to the station.", "<u>It</u> was Monday yesterday.", "<u>It</u> is important to eat breakfast every day.", "<u>It</u> snows a lot in this region in winter."]'::jsonb,4,'④의 It은 진주어인 to eat breakfast every day를 대신하는 가주어이다. 나머지 ①②③⑤는 각각 명암, 거리, 요일, 날씨를 나타내는 비인칭 주어 It으로 쓰였다.'),
(10,3,'밑줄','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

My aunt runs a small bookstore in town. <u>It</u>① takes about ten minutes to get there from my house. The store has two doors: one faces the street, and <u>another</u>② faces the garden. Some customers buy several books, while <u>others</u>③ just look around. If a book is sold out, my aunt orders a new <u>one</u>④ right away. She finds <u>it</u>⑤ rewarding to introduce good books to people.','["① It", "② another", "③ others", "④ one", "⑤ it"]'::jsonb,2,'문이 두 개뿐이므로 하나는 one, 남은 하나는 정해진 대상인 the other로 써야 하며 another는 셋 이상일 때 ''또 다른 하나''를 가리킨다. ①은 시간이 걸린다는 표현의 비인칭·가주어 It, ③은 ''다른 일부 사람들''을 뜻하는 others, ⑤는 진목적어 to introduce를 대신하는 가목적어 it으로 모두 올바르다.'),
(11,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Would you like ___ more juice?','["any", "no", "some", "none", "every"]'::jsonb,3,'some은 주로 긍정문에 쓰이지만, 권유하거나 부탁하는 의문문에서도 some을 쓴다. Would you like ~?는 상대에게 권유하는 표현이므로 any가 아닌 some이 알맞다.'),
(11,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

___ student in this class has his or her own locker.','["All", "Each", "Both", "None", "Most"]'::jsonb,2,'빈칸 뒤에 단수명사 student와 단수동사 has가 왔으므로 ''각각의''라는 뜻으로 단수 취급하는 Each가 알맞다. All, Both, Most 뒤에는 복수명사(students)가 와야 하므로 틀리다.'),
(11,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

I called Tom and Jane last night, but ___ of them answered the phone.','["both", "either", "all", "neither", "none"]'::jsonb,4,'대상이 Tom과 Jane 둘이고 but으로 보아 ''둘 다 받지 않았다''는 부정의 의미가 필요하므로 neither가 알맞다. none과 all은 셋 이상일 때 쓰고, both는 긍정의 의미라서 문맥에 맞지 않는다.'),
(11,2,'어법','다음 중 어법상 틀린 문장은?','["There isn''t any milk in the fridge.", "Both of my parents likes classical music.", "Each of the rooms has its own bathroom.", "You can choose either tea or coffee.", "All of the information was useful."]'::jsonb,2,'both는 항상 복수 취급하므로 likes가 아니라 like를 써야 한다. each는 단수 취급하여 has가 맞고, all of 뒤에 셀 수 없는 명사(information)가 오면 단수 취급하므로 was가 맞으며, 부정문의 any와 either A or B도 올바른 쓰임이다.'),
(11,3,'밑줄','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

Before the school festival, we checked <u>all</u>① of the equipment. Each of the speakers <u>were</u>② tested twice, and <u>none</u>③ of them was broken. We prepared two stages, and <u>both</u>④ of them were decorated with lights. If you have <u>any</u>⑤ questions about the schedule, please ask our staff.','["① all", "② were", "③ none", "④ both", "⑤ any"]'::jsonb,2,'''each of + 복수명사''는 단수 취급하므로 were가 아니라 was를 써야 한다. all of 뒤의 equipment는 셀 수 없는 명사라 문제가 없고, none of them was, both of them were, 조건문의 any는 모두 올바른 쓰임이다.'),
(12,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

There are ___ cookies left, so we need to buy more.','["a little", "few", "little", "much", "a great deal of"]'::jsonb,2,'cookies는 셀 수 있는 명사의 복수형이고, 더 사야 한다는 문맥상 ''거의 없는''이라는 부정적 의미의 few가 알맞다. a little, little, much, a great deal of는 모두 셀 수 없는 명사에 쓰는 수량형용사이므로 틀리다.'),
(12,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

I''m so thirsty. I''d like ___ to drink.','["something cold", "cold something", "somethings cold", "something coldly", "cold somethings"]'::jsonb,1,'-thing으로 끝나는 대명사는 형용사가 뒤에서 수식하므로 something cold의 어순이 맞다. cold something처럼 형용사를 앞에 두거나, 부사 coldly로 수식하는 것은 틀리다.'),
(12,2,'어법','다음 중 어법상 틀린 문장은?','["He has little interest in politics.", "She spent too much money on clothes.", "There were so many people at the concert.", "We have a few homework to do tonight.", "Only a little water was left in the bottle."]'::jsonb,4,'homework는 셀 수 없는 명사이므로 a few가 아니라 a little을 써야 한다. interest, money, water는 셀 수 없는 명사라 little, much, a little과 어울리고, people은 복수 취급하므로 many가 올바르다.'),
(12,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Be quiet! Don''t wake the ___ baby.','["asleep", "sleeping", "slept", "sleep", "sleepily"]'::jsonb,2,'명사 baby를 앞에서 꾸미는 한정적 용법의 자리이므로 sleeping이 알맞다. asleep처럼 a-로 시작하는 형용사(alive, alone, afraid 등)는 서술적 용법으로만 쓰여 명사 앞에 올 수 없다는 것이 함정이다.'),
(12,3,'밑줄','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

My grandmother lives <u>alone</u>① in the countryside, but she never feels <u>lonely</u>②. She grows <u>many</u>③ vegetables in her garden and needs very <u>few</u>④ help from others. Whenever I visit her, she cooks <u>something delicious</u>⑤ for me.','["① alone", "② lonely", "③ many", "④ few", "⑤ something delicious"]'::jsonb,4,'help는 셀 수 없는 명사이므로 few가 아니라 little을 써야 한다. ①의 alone은 ''혼자''라는 뜻으로 서술적으로 쓰였고, ② lonely는 feel의 보어인 형용사이며, ③ many는 복수명사 vegetables와, ⑤는 -thing+형용사의 어순으로 모두 올바르다.'),
(13,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

He drives very ___ on rainy days.','["careful", "carefully", "care", "carefulness", "more careful"]'::jsonb,2,'동사 drives를 꾸미는 말이 필요하므로 부사 carefully가 알맞다. careful은 형용사여서 동사를 수식할 수 없으며, 이는 한국 학생들이 가장 자주 혼동하는 형용사와 부사의 역할 구분 문제이다.'),
(13,1,'어법','다음 문장에서 always가 들어가기에 가장 알맞은 곳은?

I ( ① ) get ( ② ) up ( ③ ) at ( ④ ) seven ( ⑤ ) in the morning.','["①", "②", "③", "④", "⑤"]'::jsonb,1,'always 같은 빈도부사는 일반동사 앞에 위치하므로 get 앞인 ①이 알맞다. 빈도부사는 be동사나 조동사 뒤, 일반동사 앞에 온다는 규칙을 기억해야 한다.'),
(13,2,'빈칸','다음 빈칸 (A), (B)에 들어갈 말이 순서대로 바르게 짝지어진 것은?

He studied (A) for the exam, but he could (B) remember anything during the test.','["hard – hard", "hardly – hard", "hard – hardly", "hardly – hardly", "hard – almost"]'::jsonb,3,'(A)는 ''열심히''라는 뜻의 부사 hard가, (B)는 ''거의 ~않다''라는 부정의 뜻을 가진 부사 hardly가 알맞다. hard와 hardly는 형태가 비슷하지만 의미가 전혀 다르므로 주의해야 한다.'),
(13,2,'어법','다음 중 어법상 틀린 문장은?','["She is often late for meetings.", "I will never forget your kindness.", "He always is kind to his classmates.", "They usually eat dinner at seven.", "We can sometimes see stars from here."]'::jsonb,3,'빈도부사는 be동사 뒤에 와야 하므로 He is always kind가 되어야 한다. ①은 be동사 뒤, ②⑤는 조동사 뒤, ④는 일반동사 앞에 빈도부사가 온 올바른 문장이다.'),
(13,3,'밑줄','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

Kevin is a <u>highly</u>① talented violinist. He practices <u>hard</u>② every day and <u>hardly ever</u>③ misses a lesson. Last week, he arrived <u>lately</u>④ at a concert because of heavy traffic, but he still performed <u>well</u>⑤ and received great applause.','["① highly", "② hard", "③ hardly ever", "④ lately", "⑤ well"]'::jsonb,4,'''늦게 도착했다''는 의미이므로 부사 late를 써야 하며, lately는 ''최근에''라는 뜻으로 문맥에 맞지 않는다. ① highly는 ''매우'', ② hard는 ''열심히'', ③ hardly ever는 ''거의 ~않다'', ⑤ well은 ''잘''이라는 뜻으로 모두 올바르게 쓰였다.'),
(14,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

This box is ___ than that one.','["heavy", "heaviest", "heavier", "more heavy", "most heavy"]'::jsonb,3,'뒤에 than이 있으므로 비교급 heavier가 알맞다. heavy처럼 ''자음+y''로 끝나는 형용사는 y를 i로 바꾸고 -er을 붙이며, more heavy처럼 more를 함께 쓰지 않는다.'),
(14,1,'어법','다음 중 비교급 형태가 잘못 연결된 것은?','["big – bigger", "easy – easier", "famous – more famous", "good – better", "bad – badder"]'::jsonb,5,'bad의 비교급은 불규칙 변화인 worse이므로 badder는 틀리다. big은 자음을 겹쳐 bigger, easy는 y를 i로 바꿔 easier, -ous로 끝나는 2음절 형용사 famous는 more famous, good은 불규칙 변화로 better가 된다.'),
(14,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

The new stadium is ___ larger than the old one.','["very", "more", "much", "too", "so"]'::jsonb,3,'비교급 larger를 강조할 때는 much, even, still, far, a lot 등을 쓰므로 much가 알맞다. very, too, so는 원급을 수식하는 말이라 비교급 앞에 쓸 수 없다는 것이 대표적인 함정이다.'),
(14,2,'영작','다음 우리말과 일치하도록 빈칸 (A), (B)에 들어갈 말이 순서대로 바르게 짝지어진 것은?

네가 더 많이 연습할수록, 너는 더 잘하게 될 것이다.
(A) you practice, (B) you will get.','["More – better", "The more – the better", "The much – the well", "The more – better", "More – the better"]'::jsonb,2,'''~하면 할수록 더 …하다''는 ''the 비교급 ~, the 비교급 …'' 구문으로 나타내므로 The more – the better가 정답이다. 두 자리 모두 the와 비교급이 함께 있어야 하며, 한쪽에만 the를 쓰면 틀린다.'),
(14,3,'밑줄','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

City life is becoming <u>busier</u>① than before. People walk <u>more faster</u>② than they did ten years ago, and buildings grow taller <u>than</u>③ ever. Some say that the bigger a city gets, <u>the more</u>④ stressful life becomes. Others, however, believe city life is much <u>more exciting</u>⑤ than country life.','["① busier", "② more faster", "③ than", "④ the more", "⑤ more exciting"]'::jsonb,2,'fast의 비교급은 faster이며, -er 형태의 비교급에 more를 겹쳐 쓴 more faster는 이중 비교급으로 틀리다. ① busier는 올바른 비교급 형태이고, ④는 ''the 비교급, the 비교급'' 구문, ⑤는 much가 비교급 more exciting을 강조하는 올바른 표현이다.'),
(15,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Tom is as ___ as his older brother.','["taller", "tallest", "tall", "more tall", "the tallest"]'::jsonb,3,'''as ~ as'' 원급 비교 구문에서는 as와 as 사이에 형용사나 부사의 원급을 쓰므로 tall이 알맞다. 비교급 taller나 최상급 tallest를 넣는 것은 한국 학생들이 자주 하는 실수이다.'),
(15,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Mt. Everest is ___ mountain in the world.','["high", "higher", "the higher", "the highest", "most high"]'::jsonb,4,'''세계에서 가장 높은 산''이라는 의미이므로 ''the + 최상급'' 형태인 the highest가 알맞다. 최상급 앞에는 보통 the를 붙이며, 1음절 형용사 high는 most high가 아니라 highest로 만든다.'),
(15,2,'영작','다음 두 문장이 같은 뜻이 되도록 빈칸에 들어갈 말로 가장 적절한 것은?

This book is not as interesting as that one.
= That book is ___ this one.','["less interesting than", "as interesting as", "the most interesting of", "more interesting than", "not more interesting than"]'::jsonb,4,'''not as ~ as''는 앞의 대상이 뒤의 대상보다 덜하다는 뜻이므로, 주어를 바꾸면 That book이 this one보다 더 재미있다는 비교급 문장이 된다. 따라서 more interesting than이 정답이며, less interesting than을 고르면 의미가 반대가 된다.'),
(15,2,'어법','다음 중 어법상 틀린 문장은?','["He is one of the most popular singers in Korea.", "She runs as fast as her coach.", "This is the most cheapest phone in the store.", "No other student in my class is as smart as Mina.", "Health is the most important thing in life."]'::jsonb,3,'cheap의 최상급은 cheapest이며, most와 -est를 겹쳐 쓴 the most cheapest는 이중 최상급으로 틀리다. ①의 ''one of the 최상급 + 복수명사'', ④의 ''No other + 단수명사 ~ as 원급 as''는 모두 올바른 구문이다.'),
(15,3,'밑줄','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

Jeju Island is one of the most beautiful <u>island</u>① in Korea. Its beaches are <u>as clean as</u>② those of any other region. Hallasan is <u>the highest</u>③ mountain in South Korea, and the sunrise from its top is <u>the most impressive</u>④ scene I have ever watched. In spring, the whole island becomes <u>as colorful as</u>⑤ a painting.','["① island", "② as clean as", "③ the highest", "④ the most impressive", "⑤ as colorful as"]'::jsonb,1,'''one of the 최상급'' 뒤에는 반드시 복수명사가 와야 하므로 island를 islands로 고쳐야 한다. ②⑤는 ''as 원급 as'' 구문, ③④는 ''the + 최상급'' 구문으로 모두 올바르게 쓰였다.'),
(16,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Look at the beautiful picture ___ the wall.','["in", "at", "on", "under", "between"]'::jsonb,3,'그림이 벽에 붙어 있는 것은 표면에 접촉해 있는 상태이므로 전치사 on을 쓴다. in the wall은 ''벽 속에''라는 뜻이 되어 어색하며, 이는 학생들이 자주 혼동하는 표현이다.'),
(16,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

She arrived ___ Incheon Airport at 7 p.m. yesterday.','["in", "on", "at", "to", "for"]'::jsonb,3,'공항, 역처럼 비교적 좁은 지점에 도착할 때는 arrive at을 쓴다. arrive in은 나라나 도시처럼 넓은 장소에 쓰고, arrive는 자동사이므로 to를 쓰지 않는 점에 주의한다.'),
(16,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

The teacher was standing ___ the two students who were arguing.','["among", "between", "during", "along", "across"]'::jsonb,2,'''둘 사이에''는 between을 쓰므로 the two students 앞에는 between이 알맞다. among은 셋 이상의 사이에 쓰는 전치사라는 점이 대표적인 함정이며, during은 시간, along과 across는 방향·이동을 나타낸다.'),
(16,2,'빈칸','다음 빈칸 (A), (B)에 들어갈 말이 순서대로 바르게 짝지어진 것은?

A long bridge stretches (A) the river, and a small boat is passing (B) it.','["along – on", "across – under", "over – between", "across – among", "through – under"]'::jsonb,2,'다리가 강을 ''가로질러'' 놓여 있으므로 (A)는 across, 배가 다리 ''아래로'' 지나가므로 (B)는 under가 알맞다. along은 ''~을 따라'', through는 ''~을 관통하여''라는 뜻이라 다리와 강의 관계에 맞지 않는다.'),
(16,3,'밑줄','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

My town has a small library <u>next to</u>① the park. It stands <u>between</u>② the post office and the bank, so you can find it easily. Inside, thousands of books are arranged <u>on</u>③ tall wooden shelves, and beautiful paintings hang <u>in</u>④ the walls. I usually sit <u>by</u>⑤ the window and read for hours.','["① next to", "② between", "③ on", "④ in", "⑤ by"]'::jsonb,4,'그림이 벽면에 접촉하여 걸려 있는 것이므로 in이 아니라 on the walls로 써야 한다. ① next to는 ''~옆에'', ② between A and B는 ''둘 사이에'', ③ on은 표면 위, ⑤ by는 ''~곁에''라는 뜻으로 모두 올바르게 쓰였다.'),
(17,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

My birthday is ___ March.','["at", "on", "in", "for", "during"]'::jsonb,3,'월, 연도, 계절처럼 비교적 긴 기간 앞에는 전치사 in을 쓴다. at은 구체적 시각, on은 날짜나 요일 앞에 쓰므로 March 앞에는 in이 알맞다.'),
(17,1,'빈칸','다음 빈칸 (A), (B)에 들어갈 말이 순서대로 바르게 짝지어진 것은?

The concert starts (A) 8 o''clock (B) Saturday evening.','["on – at", "at – on", "in – on", "at – in", "on – in"]'::jsonb,2,'구체적인 시각(8 o''clock) 앞에는 at을 쓰고, 특정한 날의 저녁(Saturday evening)처럼 요일이 붙으면 on을 쓴다. 막연히 in the evening이라고 할 때와 달리 요일이 함께 오면 on을 쓰는 점이 함정이다.'),
(17,2,'빈칸','다음 빈칸 (A), (B)에 들어갈 말이 순서대로 바르게 짝지어진 것은?

We stayed in Busan (A) the summer vacation, and I swam in the sea (B) three hours every day.','["for – during", "while – for", "during – for", "during – during", "for – while"]'::jsonb,3,'the summer vacation처럼 특정 기간을 나타내는 명사 앞에는 during을, three hours처럼 구체적인 숫자 기간 앞에는 for를 쓴다. while은 전치사가 아니라 접속사이므로 뒤에 명사(구)만 올 수 없다.'),
(17,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Hurry up! The train leaves ___ five minutes.','["at", "on", "in", "for", "until"]'::jsonb,3,'''지금부터 ~후에''라는 의미로 미래의 일을 말할 때는 전치사 in을 쓴다. for five minutes는 ''5분 동안''이라는 지속의 의미라서 기차가 떠나는 시점을 나타낼 수 없다는 것이 함정이다.'),
(17,3,'밑줄','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

Our school festival will be held <u>on</u>① October 15th. Students have been preparing for it <u>since</u>② last month. The main event starts <u>at</u>③ noon and lasts <u>until</u>④ five o''clock. All the booths must be removed <u>until</u>⑤ 6 p.m. that day.','["① on", "② since", "③ at", "④ until", "⑤ until"]'::jsonb,5,'부스 철거는 6시까지 ''완료''되어야 하는 일이므로 완료의 기한을 나타내는 by를 써야 한다. ④의 until은 행사가 5시까지 ''계속''된다는 의미라 올바르며, 날짜 앞의 on, 시점 이후 계속을 나타내는 since, 정오 앞의 at도 모두 맞는 표현이다.'),
(18,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Water ___ at 100°C.','["boils", "boiled", "will boil", "is boiling", "has boiled"]'::jsonb,1,'물이 100도에서 끓는 것은 불변의 진리이므로 현재시제 boils를 쓴다. 과거의 사실이 아니므로 boiled는 틀리고, 일반적 사실에는 진행형이나 미래시제를 쓰지 않는다.'),
(18,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Shakespeare ___ Romeo and Juliet about 400 years ago.','["wrote", "writes", "has written", "will write", "is writing"]'::jsonb,1,'about 400 years ago라는 명백한 과거 시점 부사구가 있으므로 과거시제 wrote가 정답이다. 과거를 나타내는 부사(구)는 현재완료 has written과 함께 쓸 수 없다.'),
(18,2,'어법','다음 중 어법상 옳은 문장은?','["Columbus has discovered America in 1492.", "The earth moved around the sun.", "She go shopping every Saturday.", "Light travelled faster than sound.", "The Korean War broke out in 1950."]'::jsonb,5,'역사적 사실은 과거시제로 쓰므로 ⑤가 옳다. ①은 in 1492라는 과거 부사구가 있어 현재완료를 쓸 수 없고(discovered), ②와 ④는 불변의 진리이므로 현재시제(moves, travels)를 써야 하며, ③은 3인칭 단수 주어이므로 goes가 되어야 한다.'),
(18,2,'대화문','다음 대화의 빈칸 (A), (B)에 들어갈 말로 가장 적절한 것은?

A: What does your father do on weekends?
B: He usually (A) hiking, but last weekend he (B) at home because of the heavy rain.','["goes - stays", "went - stayed", "goes - stayed", "went - stays", "goes - has stayed"]'::jsonb,3,'usually와 함께 현재의 반복적 습관을 나타내므로 (A)는 현재시제 goes, last weekend라는 과거 시점이 있으므로 (B)는 과거시제 stayed가 맞다. ⑤처럼 last weekend와 현재완료를 함께 쓰면 틀린다.'),
(18,3,'밑줄어법','다음 글에서 밑줄 친 부분 중 어법상 <b>틀린</b> 것은?

Isaac Newton <u>was born</u>① in 1643 and <u>studied</u>② mathematics at Cambridge. One day, he saw an apple fall from a tree and <u>realized</u>③ that gravity <u>pulled</u>④ everything toward the earth. He <u>published</u>⑤ his famous book about this discovery in 1687.','["was born", "studied", "realized", "pulled", "published"]'::jsonb,4,'중력이 물체를 끌어당긴다는 것은 불변의 진리이므로 주절이 과거시제(realized)여도 종속절은 현재시제 pulls를 써야 한다. 나머지는 모두 과거의 역사적 사실이므로 과거시제가 올바르다.'),
(19,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Look at those dark clouds! It ___ soon.','["rains", "rained", "has rained", "was raining", "is going to rain"]'::jsonb,5,'현재의 확실한 근거(먹구름)를 보고 예측하는 미래는 be going to로 나타내므로 is going to rain이 정답이다. rains는 일반적 사실, rained는 과거를 나타내므로 곧 일어날 일에 대한 예측으로 쓸 수 없다.'),
(19,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

My sister ___ fifteen years old next year.','["is", "was", "will be", "has been", "be"]'::jsonb,3,'next year라는 미래 시점 부사가 있으므로 미래시제 will be가 정답이다. 현재시제 is나 과거시제 was는 미래의 일을 나타낼 수 없다.'),
(19,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

If it ___ tomorrow, we will cancel the picnic.','["will rain", "rains", "rained", "is going to rain", "has rained"]'::jsonb,2,'조건을 나타내는 부사절(if절)에서는 미래의 일이라도 현재시제로 미래를 대신하므로 rains가 정답이다. tomorrow만 보고 will rain을 고르면 틀리는 대표적인 함정이다.'),
(19,2,'어법','다음 중 어법상 <b>틀린</b> 문장은?','["I''ll wait here until she comes.", "If you need help, I will help you.", "I wonder if she will join us tomorrow.", "We will leave as soon as the rain will stop.", "He is going to study abroad next year."]'::jsonb,4,'as soon as가 이끄는 시간 부사절에서는 현재시제가 미래를 대신하므로 will stop이 아니라 stops를 써야 한다. ③의 if절은 wonder의 목적어인 명사절이므로 will을 쓴 것이 올바르다.'),
(19,3,'밑줄어법','다음 글에서 밑줄 친 부분 중 어법상 <b>틀린</b> 것은?

Our school festival <u>is going to be</u>① held next Friday. If the weather <u>will be</u>② nice, the opening ceremony <u>will take</u>③ place outside. Nobody knows whether it <u>will rain</u>④ that day, but we will keep practicing until the ceremony <u>begins</u>⑤.','["is going to be", "will be", "will take", "will rain", "begins"]'::jsonb,2,'if가 이끄는 조건 부사절에서는 현재시제가 미래를 대신하므로 will be가 아니라 is를 써야 한다. ④의 whether절은 knows의 목적어인 명사절이므로 will rain이 옳고, ⑤의 until절은 시간 부사절이므로 현재시제 begins가 옳다.'),
(20,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Listen! Someone ___ the piano in the next room.','["plays", "played", "is playing", "has played", "was playing"]'::jsonb,3,'Listen!이라는 표현으로 보아 지금 이 순간 진행 중인 동작이므로 현재진행형 is playing이 정답이다. 현재시제 plays는 습관이나 반복적인 일을 나타내므로 지금 벌어지는 일에는 맞지 않다.'),
(20,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

When I called him last night, he ___ a shower.','["was taking", "takes", "is taking", "has taken", "will take"]'::jsonb,1,'과거의 특정 시점(내가 전화했을 때)에 진행 중이던 동작이므로 과거진행형 was taking이 정답이다. is taking은 현재진행형이므로 과거 시점과 어울리지 않는다.'),
(20,2,'어법','다음 중 어법상 <b>틀린</b> 문장은?','["She is looking for her keys now.", "We were watching TV when he arrived.", "I am knowing his phone number.", "They will be traveling in Europe this time next week.", "He is having dinner with his family now."]'::jsonb,3,'know는 상태를 나타내는 동사이므로 진행형으로 쓸 수 없어 I know his phone number가 되어야 한다. ⑤의 have는 ''먹다''라는 동작의 의미이므로 진행형이 가능하다는 점에 주의한다.'),
(20,2,'영작','다음 우리말을 영어로 바르게 옮긴 것은?

내일 이 시간에 우리는 바다에서 수영하고 있을 것이다.','["We swim in the sea at this time tomorrow.", "We will be swimming in the sea at this time tomorrow.", "We were swimming in the sea at this time tomorrow.", "We have swum in the sea at this time tomorrow.", "We will been swimming in the sea at this time tomorrow."]'::jsonb,2,'미래의 특정 시점(내일 이 시간)에 진행 중일 동작은 미래진행형 will be v-ing로 나타내므로 ②가 정답이다. ⑤는 be동사 원형 be 대신 been을 써서 어법상 틀린 형태이다.'),
(20,3,'밑줄어법','다음 글에서 밑줄 친 부분 중 어법상 <b>틀린</b> 것은?

These days more and more students <u>are preparing</u>① for exams online. Yesterday afternoon, while I <u>was studying</u>② in the library, my phone rang. My mother <u>wanted</u>③ to know what I was doing. I told her that I <u>was belonging</u>④ to a study group and that we <u>were discussing</u>⑤ our science project.','["are preparing", "was studying", "wanted", "was belonging", "were discussing"]'::jsonb,4,'belong은 소유·소속의 상태를 나타내는 동사로 진행형을 쓸 수 없으므로 belonged가 되어야 한다. discuss는 동작 동사이므로 ⑤의 과거진행형은 올바르며, ①②도 각각 진행 중인 동작을 바르게 나타낸다.'),
(21,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

She ___ in Busan since 2015.','["lives", "lived", "is living", "will live", "has lived"]'::jsonb,5,'since 2015는 과거에 시작된 일이 현재까지 계속됨을 나타내므로 현재완료 has lived가 정답이다. 단순 과거 lived는 지금은 살지 않는다는 의미가 되어 since와 어울리지 않는다.'),
(21,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Tom is not here now. He ___ to London.','["has been", "has gone", "have gone", "has going", "is gone"]'::jsonb,2,'런던에 가서 지금 여기에 없다는 결과를 나타내므로 has gone to가 정답이다. has been to는 ''~에 가 본 적이 있다(경험)''는 뜻이어서 지금 없다는 문맥과 맞지 않고, 주어가 3인칭 단수이므로 have gone도 틀리다.'),
(21,2,'어법','다음 중 어법상 <b>틀린</b> 문장은?','["I have never eaten Indian food.", "Have you ever ridden a horse?", "She has just left the office.", "When have you arrived in Korea?", "We have known each other since middle school."]'::jsonb,4,'의문사 when은 특정 과거 시점을 묻기 때문에 현재완료와 함께 쓸 수 없으므로 When did you arrive in Korea?가 되어야 한다. 나머지는 각각 경험(①②), 완료(③), 계속(⑤)을 나타내는 올바른 현재완료 문장이다.'),
(21,2,'용법구별','다음 밑줄 친 부분과 쓰임(용법)이 같은 것은?

I <u>have lost</u> my watch, so I don''t know what time it is.','["He has just finished his homework.", "I have been to Paris twice.", "She has gone to Canada to study.", "We have studied French for five years.", "Have you ever seen a shooting star?"]'::jsonb,3,'제시문의 have lost는 시계를 잃어버려서 지금 없다는 ''결과'' 용법이며, ③의 has gone도 캐나다에 가서 지금 여기 없다는 결과 용법이다. ①은 완료, ②⑤는 경험, ④는 계속 용법이다.'),
(21,3,'밑줄어법','다음 글에서 밑줄 친 부분 중 어법상 <b>틀린</b> 것은?

Minji <u>has studied</u>① English since she <u>was</u>② seven years old. She <u>has visited</u>③ England twice, and last summer she <u>has stayed</u>④ in London for a month. Now she <u>wants</u>⑤ to study at a university there.','["has studied", "was", "has visited", "has stayed", "wants"]'::jsonb,4,'last summer라는 명백한 과거 시점 부사구가 있으므로 현재완료가 아닌 과거시제 stayed를 써야 한다. ①은 since와 함께 쓰인 계속 용법, ③은 twice와 함께 쓰인 경험 용법으로 모두 올바르다.'),
(22,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

It ___ for three hours, and it is still raining now.','["rains", "rained", "is raining", "has been raining", "was raining"]'::jsonb,4,'세 시간 전에 시작된 비가 지금도 계속 내리고 있으므로 현재완료 진행형 has been raining이 정답이다. 단순 과거 rained나 과거진행 was raining은 지금도 계속되고 있다는 뒷문장과 맞지 않는다.'),
(22,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

When I arrived at the station, the train ___.','["had already left", "has already left", "already leaves", "is already leaving", "will already leave"]'::jsonb,1,'기차가 떠난 것은 내가 도착한 과거 시점보다 더 이전의 일이므로 과거완료 had already left를 쓴다. 현재완료 has left는 기준 시점이 현재일 때 쓰므로 과거의 기준 시점(arrived)과 함께 쓸 수 없다.'),
(22,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

She ___ for the company for five years before she moved to Seoul.','["works", "has worked", "is working", "had worked", "will work"]'::jsonb,4,'서울로 이사한 과거 시점 이전까지 5년간 계속된 일이므로 과거완료 had worked가 정답이다. 현재완료 has worked는 현재까지 계속되는 일에 쓰므로 과거 시점(moved) 이전의 일에는 쓸 수 없다.'),
(22,2,'어법','다음 중 어법상 옳은 문장은?','["I have been knowing him for years.", "He said that he has finished the work.", "They had been waiting for an hour when the bus finally arrived.", "She has been exercising since two hours.", "By the time we arrived at the theater, the movie has started."]'::jsonb,3,'버스가 도착한 과거 시점까지 한 시간 동안 계속된 동작이므로 과거완료 진행형을 쓴 ③이 옳다. ①은 상태동사 know를 진행형으로 쓸 수 없고, ④는 since two hours가 아니라 for two hours여야 하며, ②⑤는 과거 기준 시점이 있으므로 had finished, had started가 되어야 한다.'),
(22,3,'밑줄어법','다음 글에서 밑줄 친 부분 중 어법상 <b>틀린</b> 것은?

When Jake <u>got</u>① to the airport, he <u>realized</u>② that he <u>had left</u>③ his passport at home. He <u>had been packing</u>④ in a hurry that morning, so he <u>hasn''t checked</u>⑤ his bag carefully.','["got", "realized", "had left", "had been packing", "hasn''t checked"]'::jsonb,5,'가방을 확인하지 않은 것은 공항에 도착한 과거 시점보다 이전의 일이므로 현재완료가 아닌 과거완료 hadn''t checked를 써야 한다. ③은 여권을 두고 온 것이 깨달은 시점보다 앞선 일이므로 과거완료가 올바르고, ④는 그 이전에 계속된 동작이므로 과거완료 진행형이 올바르다.'),
(23,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

He practiced hard every day, so now he ___ swim across the river.','["can", "cans", "can to", "will can", "is able"]'::jsonb,1,'현재의 능력을 나타내는 조동사 can이 정답이며, 조동사 뒤에는 동사원형이 온다. 조동사는 주어가 3인칭 단수여도 -s를 붙이지 않으므로 cans는 틀리고, is able은 뒤에 to가 있어야 한다.'),
(23,1,'영작','다음 우리말과 일치하도록 빈칸에 들어갈 말로 가장 적절한 것은?

그는 틀림없이 피곤할 것이다. 하루 종일 일했다.
→ He ___ be tired. He has worked all day.','["must", "may not", "cannot", "should not", "would not"]'::jsonb,1,'''틀림없이 ~일 것이다''라는 강한 확신의 추측은 must로 나타낸다. cannot be는 ''~일 리가 없다''는 정반대의 의미이므로 문맥에 맞지 않는다.'),
(23,2,'영작','다음 우리말과 일치하도록 빈칸에 들어갈 말로 가장 적절한 것은?

그 소문은 사실일 리가 없다. 아무도 그것을 믿지 않는다.
→ The rumor ___ true. Nobody believes it.','["must be", "cannot be", "may be", "must not be", "should be"]'::jsonb,2,'''~일 리가 없다''는 강한 부정적 추측은 cannot be로 나타낸다. must not은 ''~해서는 안 된다''는 금지의 의미가 강하며, ''~일 리가 없다''는 추측의 부정은 must의 반대인 cannot을 쓴다는 점이 핵심 함정이다.'),
(23,2,'용법구별','다음 중 밑줄 친 must의 의미가 나머지 넷과 <b>다른</b> 것은?','["He <u>must</u> be over sixty years old.", "The story <u>must</u> be true.", "You <u>must</u> finish the report by Friday.", "She <u>must</u> be very happy to hear the news.", "They <u>must</u> be twins; they look exactly alike."]'::jsonb,3,'③의 must는 ''~해야 한다''는 의무의 의미이고, 나머지는 모두 ''~임에 틀림없다''는 강한 추측의 의미이다. 추측의 must는 주로 뒤에 be동사나 상태를 나타내는 표현과 함께 쓰인다.'),
(23,3,'밑줄어법','다음 글에서 밑줄 친 부분 중 어법상 <b>틀린</b> 것은?

My brother <u>is able to</u>① repair almost anything. Yesterday he <u>couldn''t</u>② find his toolbox and asked me where it <u>might be</u>③. I told him it <u>must being</u>④ in the garage, and I was right. He <u>was able to</u>⑤ fix the broken door before dinner.','["is able to", "couldn''t", "might be", "must being", "was able to"]'::jsonb,4,'조동사 must 뒤에는 동사원형이 와야 하므로 must being이 아니라 must be가 되어야 한다. ③의 might는 약한 추측을 나타내는 올바른 표현이고, ①⑤의 be able to는 can을 대신하는 능력 표현으로 어법상 문제가 없다.'),
(24,1,'영작','다음 우리말과 일치하도록 빈칸에 들어갈 말로 가장 적절한 것은?

너는 도서관에서 조용히 해야 한다.
→ You ___ be quiet in the library.','["may", "must", "cannot", "would", "won''t"]'::jsonb,2,'''~해야 한다''는 의무는 must로 나타낸다. may는 ''~해도 좋다''는 허가, cannot은 ''~할 수 없다''는 의미이므로 우리말과 일치하지 않는다.'),
(24,1,'영작','다음 우리말과 일치하도록 빈칸에 들어갈 말로 가장 적절한 것은?

너는 복도에서 뛰어서는 안 된다. 위험하다.
→ You ___ run in the hallway. It''s dangerous.','["don''t have to", "have to", "must not", "may", "would"]'::jsonb,3,'''~해서는 안 된다''는 금지는 must not으로 나타낸다. don''t have to는 ''~할 필요가 없다''는 불필요의 의미이므로 금지와 혼동하지 않도록 주의해야 한다.'),
(24,2,'어법','다음 중 어법상 <b>틀린</b> 문장은?','["May I borrow your pen for a minute?", "You had better to take an umbrella with you.", "She will have to wait until next Monday.", "You must not park your car here.", "Students should follow the school rules."]'::jsonb,2,'had better 뒤에는 to부정사가 아닌 동사원형이 와야 하므로 had better take가 되어야 한다. ③처럼 미래의 의무는 will must가 아니라 will have to로 나타내는 것이 올바르다.'),
(24,2,'대화문','다음 대화의 빈칸에 들어갈 말로 가장 적절한 것은?

A: Do I have to wear a suit to the party?
B: No, you ___. It''s a casual party, so jeans are fine.','["must not", "can''t", "shouldn''t", "may not", "don''t have to"]'::jsonb,5,'정장을 입을 ''필요가 없다''는 불필요의 의미이므로 don''t have to가 정답이다. must not은 ''입어서는 안 된다''는 금지의 뜻이 되어, 청바지도 괜찮다는 뒷말과 어울리지 않는다.'),
(24,3,'밑줄어법','다음 글에서 밑줄 친 부분 중 어법상 <b>틀린</b> 것은?

If you want to stay healthy, you <u>should exercise</u>① regularly. You <u>don''t have to</u>② join an expensive gym; walking every day is enough. However, you <u>had better not</u>③ skip meals, and you <u>must to</u>④ get enough sleep. Doctors say teenagers <u>ought to</u>⑤ sleep at least eight hours a night.','["should exercise", "don''t have to", "had better not", "must to", "ought to"]'::jsonb,4,'조동사 must 뒤에는 to 없이 동사원형이 와야 하므로 must get이 되어야 한다. ③의 had better의 부정형은 had better not으로 올바르고, ⑤의 ought to는 to를 포함하는 조동사 표현이므로 올바르다.'),
(25,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

There ___ be a big tree in front of my house, but it''s gone now.','["used to", "would", "uses to", "is used to", "will"]'::jsonb,1,'과거에는 있었지만 지금은 없는 ''과거의 상태''는 used to로 나타낸다. would는 과거의 반복된 ''행동''에만 쓰고 상태에는 쓸 수 없으므로, There would be는 틀린 표현이다.'),
(25,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

When I was a child, my family ___ go camping every summer.','["will", "must", "would", "had better", "should"]'::jsonb,3,'과거에 반복적으로 했던 행동은 would로 나타내므로 would go가 정답이다. will은 미래를 나타내므로 When I was a child라는 과거 문맥과 맞지 않는다.'),
(25,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

The ground is wet everywhere. It ___ last night.','["must have rained", "should have rained", "must rain", "cannot have rained", "may rain"]'::jsonb,1,'땅이 젖어 있다는 현재의 확실한 근거로 과거의 일을 강하게 추측하는 것이므로 must have v-ed 형태인 must have rained가 정답이다. should have rained는 ''비가 왔어야 했는데 (안 왔다)''는 후회·유감의 의미이므로 문맥에 맞지 않는다.'),
(25,2,'영작','다음 우리말을 영어로 바르게 옮긴 것은?

나는 어제 우산을 가져갔어야 했는데. (실제로는 가져가지 않아 후회함)','["I must have taken an umbrella yesterday.", "I should have taken an umbrella yesterday.", "I cannot have taken an umbrella yesterday.", "I should take an umbrella yesterday.", "I would take an umbrella yesterday."]'::jsonb,2,'과거에 하지 않은 일에 대한 후회는 should have v-ed(~했어야 했는데)로 나타내므로 ②가 정답이다. ①의 must have taken은 ''가져갔음에 틀림없다''는 과거 추측의 의미이므로 후회의 뜻과 다르다.'),
(25,3,'밑줄어법','다음 글에서 밑줄 친 부분 중 어법상 <b>틀린</b> 것은?

My grandfather <u>used to live</u>① in the countryside. He <u>would take</u>② long walks every morning. There <u>would be</u>③ an old well in his yard, but it is gone now. He <u>must have loved</u>④ nature very much. I <u>should have visited</u>⑤ him more often before he moved to the city.','["used to live", "would take", "would be", "must have loved", "should have visited"]'::jsonb,3,'우물이 있었다는 것은 과거의 ''상태''이므로 would가 아닌 used to be를 써야 한다. would는 과거의 반복적 행동(②의 would take)에만 쓸 수 있고, ④⑤는 각각 과거에 대한 강한 추측과 후회를 나타내는 올바른 표현이다.'),
(26,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

This novel ___ by Hemingway in 1952.','["wrote", "is written", "was wrote", "was written", "has written"]'::jsonb,4,'주어인 소설은 ''쓰여진'' 대상이고 in 1952라는 과거 시점이 있으므로 과거시제 수동태 was written이 정답이다. 수동태는 be동사 + 과거분사 형태이므로 was wrote처럼 과거형을 쓰면 틀린다.'),
(26,1,'문장전환','다음 문장을 수동태로 바르게 바꾼 것은?

Tom broke the window.','["The window was broken by Tom.", "The window was broke by Tom.", "The window is broken by Tom.", "The window broke by Tom.", "The window has broken by Tom."]'::jsonb,1,'능동태의 목적어 the window를 주어로 하고, 과거시제이므로 was + 과거분사 broken을 쓴 ①이 정답이다. ②는 과거분사 자리에 과거형 broke를 썼고, ③은 시제가 현재로 바뀌어 틀리다.'),
(26,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

All safety rules must ___ by every worker in the factory.','["follow", "be following", "be followed", "followed", "have followed"]'::jsonb,3,'규칙은 ''지켜지는'' 대상이므로 수동태가 필요하고, 조동사가 있는 수동태는 조동사 + be + 과거분사 형태이므로 be followed가 정답이다. 조동사 뒤라고 해서 동사원형 follow만 쓰면 능동의 의미가 되어 틀린다.'),
(26,2,'어법','다음 중 어법상 <b>틀린</b> 문장은?','["English is spoken in many countries.", "The bridge is being repaired now.", "A new library will be built next year.", "The problem was disappeared suddenly.", "This song has been loved for decades."]'::jsonb,4,'disappear는 목적어를 갖지 않는 자동사이므로 수동태로 쓸 수 없어 The problem disappeared suddenly가 되어야 한다. ②는 현재진행 수동태(be being p.p.), ⑤는 현재완료 수동태(have been p.p.)로 모두 올바른 형태이다.'),
(26,3,'밑줄어법','다음 글에서 밑줄 친 부분 중 어법상 <b>틀린</b> 것은?

The Eiffel Tower <u>was designed</u>① by Gustave Eiffel and <u>was completed</u>② in 1889. At first, it <u>was criticized</u>③ by many artists in Paris. Today, however, its lights <u>can be seen</u>④ from far away, and it <u>is visiting</u>⑤ by millions of tourists every year.','["was designed", "was completed", "was criticized", "can be seen", "is visiting"]'::jsonb,5,'에펠탑은 관광객들에 의해 ''방문되는'' 대상이므로 진행형이 아닌 수동태 is visited를 써야 한다. ④는 조동사 can이 있는 수동태로 can be seen이 올바른 형태이다.'),
(27,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

The top of the mountain is covered ___ snow all year round.','["by", "with", "at", "from", "of"]'::jsonb,2,'be covered with는 ''~로 덮여 있다''라는 뜻으로 by 대신 with를 쓰는 수동태 관용 표현이다. 수동태라고 해서 무조건 by를 쓰는 것이 아니라는 점이 출제 포인트이다.'),
(27,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

She is very interested ___ Korean history.','["by", "at", "in", "with", "on"]'::jsonb,3,'be interested in은 ''~에 관심이 있다''라는 뜻으로 전치사 in을 쓰는 수동태 관용 표현이다. by나 at을 쓰지 않도록 주의해야 한다.'),
(27,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

A birthday cake was made ___ me by my mother this morning.','["to", "of", "for", "with", "by"]'::jsonb,3,'4형식 문장에서 make의 직접목적어를 주어로 수동태를 만들면 간접목적어 앞에 전치사 for를 쓴다. give, send 등은 to를 쓰지만 make, buy, cook 등은 for를 쓴다는 점이 핵심이다.'),
(27,2,'문장전환','다음 문장을 수동태로 바꿀 때 빈칸에 들어갈 말로 가장 적절한 것은?

His parents made him clean his room.
→ He was made ___ his room by his parents.','["clean", "cleaned", "cleaning", "to clean", "to cleaning"]'::jsonb,4,'사역동사 make가 쓰인 5형식 문장을 수동태로 바꾸면 목적격보어였던 동사원형이 to부정사로 바뀌므로 to clean이 정답이다. 능동태에서 원형(clean)이었다고 해서 수동태에서도 그대로 두면 틀린다.'),
(27,3,'밑줄어법','다음 글에서 밑줄 친 부분 중 어법상 <b>틀린</b> 것은?

Jina <u>was brought up</u>① by her grandparents. At school, she <u>is looked up to</u>② by many students because she always takes care of younger children. Last week she was elected class president, and everyone <u>was satisfied with</u>③ the result. Her warm heart <u>is respected</u>④ by her teachers, and her name <u>is known by</u>⑤ every student in the school.','["was brought up", "is looked up to", "was satisfied with", "is respected", "is known by"]'::jsonb,5,'''~에게 알려져 있다''는 be known to를 쓰므로 is known by가 아니라 is known to가 되어야 한다. ②는 구동사 look up to를 수동태로 만들 때 전치사 to까지 하나의 덩어리로 유지한 올바른 형태이고, ③의 be satisfied with도 올바른 관용 표현이다.'),
(28,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

He promised ___ back before dark.','["come", "coming", "to come", "came", "to coming"]'::jsonb,3,'promise는 to부정사를 목적어로 취하는 동사이므로 to come이 알맞다. coming처럼 동명사를 쓰거나 come처럼 동사원형을 그대로 쓰면 목적어 자리에 올 수 없어 틀린다.'),
(28,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

I don''t know ___ this machine.','["how to use", "how using", "how use", "what to use", "to how use"]'::jsonb,1,'「의문사+to부정사」가 know의 목적어로 쓰인 형태로, ''이 기계를 어떻게 사용하는지''라는 뜻의 how to use가 알맞다. what to use는 use의 목적어가 이미 this machine으로 있어 어법상 성립하지 않고, how using은 의문사 뒤에 동명사를 쓸 수 없어 틀린다.'),
(28,2,'어법','다음 중 어법상 옳은 문장은?','["This is important to exercise every day.", "I want to knowing where to park my car.", "To make new friends are not always easy.", "My plan is to finish the report by Friday.", "He decided buying a new laptop."]'::jsonb,4,'④는 to부정사가 be동사 뒤에서 보어로 쓰인 올바른 문장이다. ①은 가주어 구문이므로 This가 아니라 It을 써야 하고, ③은 to부정사 주어는 단수 취급하므로 are가 아니라 is를 써야 하며, ⑤는 decide가 to부정사를 목적어로 취하므로 to buy가 되어야 한다.'),
(28,2,'문장전환','다음 문장과 의미가 같은 것은?

Tell me when to start the meeting.','["Tell me when I started the meeting.", "Tell me when I should start the meeting.", "Tell me when starting the meeting.", "Tell me when should I start the meeting.", "Tell me when I start to the meeting."]'::jsonb,2,'「의문사+to부정사」는 「의문사+주어+should+동사원형」으로 바꿔 쓸 수 있으므로 when I should start가 알맞다. ④는 간접의문문인데 「의문사+동사+주어」의 의문문 어순을 써서 틀렸고, ①은 과거시제로 의미 자체가 달라진다.'),
(28,3,'밑줄어법','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

<u>It</u>① is not easy <u>to learn</u>② a foreign language. Many students don''t know <u>how to memorize</u>③ new words effectively. My advice is <u>keep</u>④ a small vocabulary notebook and review it every day. If you do so, you will find <u>it</u>⑤ possible to remember hundreds of words.','["It", "to learn", "how to memorize", "keep", "it"]'::jsonb,4,'④는 be동사 is의 보어 자리이므로 동사원형 keep이 아니라 to부정사 to keep을 써야 한다. ①은 진주어 to learn을 대신하는 가주어, ⑤는 진목적어 to remember를 대신하는 가목적어로 모두 올바르게 쓰였다.'),
(29,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

I need a pen ___.','["write", "to write", "to write with", "writing", "to writing"]'::jsonb,3,'''~을 가지고 쓸 펜''이라는 의미로, write a pen이 아니라 write with a pen의 관계이므로 전치사 with가 반드시 필요하다. to write는 전치사가 빠져 있어 한국 학생들이 가장 흔히 고르는 오답이다.'),
(29,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

I''m glad ___ you again.','["see", "saw", "to see", "seeing", "to seeing"]'::jsonb,3,'glad, happy, sorry 같은 감정 형용사 뒤에는 감정의 원인을 나타내는 to부정사(부사적 용법)를 쓰므로 to see가 알맞다. seeing처럼 동명사를 쓰거나 동사원형 see를 그대로 쓰는 것은 어법상 불가능하다.'),
(29,2,'용법구별','다음 문장의 밑줄 친 to부정사와 쓰임이 같은 것은?

She woke up <u>to find</u> her room flooded.','["I have a lot of homework to do tonight.", "He exercises every day to stay healthy.", "We were surprised to hear the news.", "My grandmother lived to be ninety years old.", "To travel around Europe is my dream."]'::jsonb,4,'주어진 문장의 to find는 ''깨어나 보니 (결국) ~을 발견했다''는 결과를 나타내는 부사적 용법이며, ④의 lived to be ninety(살아서 90세가 되었다)도 결과 용법이다. ②는 목적, ③은 감정의 원인, ①은 명사를 수식하는 형용사적 용법이라 쓰임이 다르다.'),
(29,2,'영작','다음 우리말을 영어로 옳게 옮긴 것은?

그 아이들은 앉을 의자가 필요하다.','["The children need a chair to sit.", "The children need a chair to sit on.", "The children need to sit a chair.", "The children need a chair sitting on.", "The children need a chair for sit on."]'::jsonb,2,'sit on a chair(의자에 앉다)의 관계이므로 명사를 수식하는 to부정사 뒤에 전치사 on을 남겨 a chair to sit on으로 써야 한다. ①은 전치사 on이 빠져서 틀렸고, ⑤는 to부정사 대신 for sit라는 불가능한 형태를 썼다.'),
(29,3,'밑줄어법','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

Last winter, Mina saved money <u>to buy</u>① a present for her mother. She wanted something special <u>to give</u>② her on her birthday. She visited several shops, <u>only to find</u>③ that everything was too expensive. Finally, she decided to make a scarf herself, and her mother was very pleased <u>receiving</u>④ such a heartfelt gift. It gave Mina a good reason <u>to feel</u>⑤ proud of herself.','["to buy", "to give", "only to find", "receiving", "to feel"]'::jsonb,4,'④는 pleased라는 감정 형용사 뒤에서 감정의 원인을 나타내야 하므로 동명사 receiving이 아니라 to부정사 to receive를 써야 한다. ①은 목적, ③은 「only+to부정사」로 실망스러운 결과를 나타내는 올바른 표현이며, ②와 ⑤는 각각 앞의 명사를 수식하는 형용사적 용법으로 맞다.'),
(30,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

It was very kind ___ you to help the old man.','["for", "of", "to", "with", "by"]'::jsonb,2,'kind, nice, foolish처럼 사람의 성격이나 성품을 나타내는 형용사가 올 때 to부정사의 의미상 주어는 「of+목적격」으로 쓴다. for는 easy, difficult, important 등 일반적인 형용사 뒤에 쓰이므로 이 문장에서는 틀린다.'),
(30,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

This box is too heavy for me ___.','["carry", "to carry", "carrying", "carried", "to carrying"]'::jsonb,2,'「too+형용사+for+의미상 주어+to부정사」는 ''너무 ~해서 …할 수 없다''라는 뜻의 구문이므로 to carry가 알맞다. too ~ 구문 뒤에는 반드시 to부정사가 와야 하며 동명사 carrying이나 동사원형 carry는 쓸 수 없다.'),
(30,2,'문장전환','다음 문장과 의미가 같은 것은?

The coffee was so hot that I couldn''t drink it.','["The coffee was too hot for me to drink it.", "The coffee was too hot for me to drink.", "The coffee was hot enough for me to drink.", "The coffee was too hot of me to drink.", "The coffee was so hot to drink for me."]'::jsonb,2,'「so+형용사+that+주어+can''t」는 「too+형용사+for+의미상 주어+to부정사」로 바꿔 쓸 수 있다. ①은 문장의 주어 The coffee가 drink의 목적어와 같으므로 문장 끝의 it을 반드시 없애야 해서 틀렸고, ③은 ''마실 수 있을 만큼 뜨거웠다''는 반대 의미가 된다.'),
(30,2,'문장전환','다음 문장을 바꿔 쓸 때 빈칸에 들어갈 말로 가장 적절한 것은?

It seems that she knows the answer.
= She seems ___ the answer.','["to know", "know", "knowing", "to knowing", "that know"]'::jsonb,1,'「It seems that+주어+동사」는 「주어+seem+to부정사」로 바꿔 쓸 수 있으므로 to know가 알맞다. seem 뒤에는 동명사나 동사원형이 올 수 없으므로 knowing과 know는 모두 틀린다.'),
(30,3,'밑줄어법','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

The math problem looked simple, but it was <u>too difficult for</u>① most students to solve. Only Jiho seemed <u>to understand</u>② it right away. It was clever <u>of</u>③ him to use a diagram. The teacher said the problem was hard enough <u>challenging</u>④ even top students, and it was necessary <u>for</u>⑤ everyone to review the basic concepts again.','["too difficult for", "to understand", "of", "challenging", "for"]'::jsonb,4,'「형용사+enough」 뒤에는 to부정사가 와야 하므로 ④는 challenging이 아니라 to challenge가 되어야 한다. ③은 clever가 성품 형용사이므로 의미상 주어를 of him으로 쓴 것이 맞고, ⑤는 necessary가 일반 형용사이므로 for everyone이 맞다.'),
(31,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

My mom told me ___ the dishes after dinner.','["wash", "washes", "to wash", "washing", "washed"]'::jsonb,3,'tell은 5형식에서 「tell+목적어+to부정사」의 형태로 목적격 보어에 to부정사를 취하므로 to wash가 알맞다. tell은 사역동사가 아니므로 동사원형 wash를 쓰면 틀린다.'),
(31,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

The teacher made us ___ the classroom.','["clean", "to clean", "cleaning", "cleaned", "to cleaning"]'::jsonb,1,'make는 사역동사이므로 목적격 보어로 원형부정사(동사원형)를 취해 made us clean이 되어야 한다. to clean은 want, tell 같은 일반 동사의 목적격 보어 형태를 잘못 적용한 오답이다.'),
(31,2,'어법','다음 중 어법상 <b>틀린</b> 문장은?','["I want you to come to my birthday party.", "She asked him to turn down the music.", "My dad let me to stay up late last night.", "We saw the children play soccer in the park.", "The doctor advised her to get more sleep."]'::jsonb,3,'let은 사역동사이므로 목적격 보어로 원형부정사를 취해 let me stay가 되어야 하며, to stay는 틀린 형태다. want, ask, advise는 목적격 보어로 to부정사를 취하고, 지각동사 saw는 원형부정사 play를 취하므로 나머지는 모두 옳다.'),
(31,2,'빈칸짝','다음 두 문장의 빈칸에 들어갈 말이 순서대로 바르게 짝지어진 것은?

• The movie made me ___ about my future.
• The coach wants his players ___ hard every day.','["think – train", "think – to train", "to think – to train", "thinking – training", "to think – train"]'::jsonb,2,'사역동사 make는 목적격 보어로 원형부정사 think를, want는 목적격 보어로 to부정사 to train을 취한다. 두 동사의 보어 형태가 서로 다르다는 점이 핵심이며, 이를 반대로 적용한 ⑤가 대표적인 함정이다.'),
(31,3,'밑줄어법','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

Yesterday my uncle had me <u>help</u>① him in his garden. He asked me <u>to water</u>② the flowers and let me <u>pick</u>③ some tomatoes. While working, I heard birds <u>sing</u>④ in the trees. My uncle always encourages me <u>spending</u>⑤ more time outdoors.','["help", "to water", "pick", "sing", "spending"]'::jsonb,5,'encourage는 「encourage+목적어+to부정사」의 형태를 취하므로 ⑤는 spending이 아니라 to spend가 되어야 한다. ①과 ③은 사역동사 have와 let 뒤의 원형부정사, ④는 지각동사 heard 뒤의 원형부정사로 모두 올바르다.'),
(32,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

___ pictures is my favorite hobby.','["Take", "Takes", "Taking", "Taken", "To taking"]'::jsonb,3,'문장의 주어 자리이므로 동명사 Taking이 알맞으며, ''사진 찍는 것''이라는 의미가 된다. 동사원형 Take는 주어 자리에 올 수 없고, To taking은 존재하지 않는 형태다.'),
(32,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Thank you for ___ me to the party.','["invite", "to invite", "inviting", "invited", "to inviting"]'::jsonb,3,'전치사 for 뒤에는 동사가 올 경우 반드시 동명사를 써야 하므로 inviting이 알맞다. 전치사 뒤에 to부정사(to invite)를 쓰는 것은 한국 학생들이 자주 하는 실수로, 어법상 불가능하다.'),
(32,2,'어법','다음 중 어법상 옳은 문장은?','["He is good at play the guitar.", "Reading comic books are fun.", "My job is teach English to children.", "She left without saying goodbye.", "I''m interested in learn foreign languages."]'::jsonb,4,'④는 전치사 without 뒤에 동명사 saying을 올바르게 썼다. ①과 ⑤는 전치사 뒤에 동사원형을 써서 틀렸고(playing, learning이 되어야 함), ②는 동명사 주어가 단수 취급이므로 are가 아니라 is를 써야 하며, ③은 보어 자리에 동사원형이 아닌 teaching(또는 to teach)을 써야 한다.'),
(32,2,'영작','다음 우리말을 영어로 옳게 옮긴 것은?

나는 시험에 떨어질까 봐 걱정된다.','["I''m worried about fail the exam.", "I''m worried about to fail the exam.", "I''m worried about failing the exam.", "I''m worried to failing about the exam.", "I''m worried about being fail the exam."]'::jsonb,3,'전치사 about의 목적어로는 동명사 failing을 써야 하므로 ③이 옳다. ①은 전치사 뒤에 동사원형을, ②는 전치사 뒤에 to부정사를 써서 틀렸는데, 둘 다 전치사의 목적어 규칙을 놓친 전형적인 오답이다.'),
(32,3,'밑줄어법','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

<u>Keeping</u>① a diary in English is a great way to improve your writing. Some people give up after a few days because they are afraid of <u>making</u>② mistakes. However, <u>writing</u>③ just three sentences a day <u>are</u>④ enough at first. Before <u>going</u>⑤ to bed, spend five minutes on your diary.','["Keeping", "making", "writing", "are", "going"]'::jsonb,4,'동명사구 주어(writing just three sentences a day)는 단수 취급하므로 ④는 are가 아니라 is가 되어야 한다. ①은 문장의 주어로 쓰인 동명사, ②와 ⑤는 각각 전치사 of와 Before의 목적어로 쓰인 동명사로 모두 올바르다.'),
(33,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

He finished ___ his homework before dinner.','["do", "to do", "doing", "did", "to doing"]'::jsonb,3,'finish는 동명사만을 목적어로 취하는 동사이므로 doing이 알맞다. to do는 want, hope처럼 to부정사를 취하는 동사와 혼동한 오답으로, finish 뒤에는 쓸 수 없다.'),
(33,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Would you mind ___ the window? It''s cold in here.','["close", "to close", "closing", "closed", "to closing"]'::jsonb,3,'mind는 enjoy, finish, give up과 함께 동명사만을 목적어로 취하는 동사이므로 closing이 알맞다. to close는 to부정사를 취하는 동사들과 혼동하기 쉬운 대표적인 함정 선지다.'),
(33,2,'영작','다음 우리말을 영어로 옳게 옮긴 것은?

너는 어제 그 파일을 나에게 보낸 것을 기억하니?','["Do you remember to send me the file yesterday?", "Do you remember sending me the file yesterday?", "Do you remember send me the file yesterday?", "Did you remember to sending me the file yesterday?", "Do you remember that sending me the file yesterday?"]'::jsonb,2,'''(과거에) ~한 것을 기억하다''는 remember 뒤에 동명사를 써야 하므로 remember sending이 옳다. ①의 remember to send는 ''(앞으로) 보낼 것을 기억하다''라는 미래의 의미가 되어 yesterday와 맞지 않는다.'),
(33,2,'빈칸짝','다음 두 문장의 빈칸에 들어갈 말이 순서대로 바르게 짝지어진 것은?

• Don''t forget ___ the door when you leave.
• I''ll never forget ___ the northern lights in Iceland last year.','["to lock – to see", "to lock – seeing", "locking – seeing", "locking – to see", "lock – seeing"]'::jsonb,2,'첫 문장은 ''(앞으로) 잠글 것을 잊지 마라''는 미래의 일이므로 forget to lock, 둘째 문장은 ''(과거에) 본 것을 잊지 못할 것이다''라는 과거의 경험이므로 forget seeing을 쓴다. forget은 뒤에 오는 형태에 따라 의미가 달라지는 동사라는 점이 핵심이다.'),
(33,3,'밑줄어법','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

When Sora moved to a new school, she tried <u>to make</u>① friends, but it wasn''t easy. She stopped <u>to worry</u>② about what others thought and joined the drama club. Soon she began <u>to enjoy</u>③ school life. Now she remembers <u>feeling</u>④ lonely at first, but she doesn''t regret <u>changing</u>⑤ schools at all.','["to make", "to worry", "to enjoy", "feeling", "changing"]'::jsonb,2,'문맥상 ''다른 사람들의 시선에 대해 걱정하는 것을 그만두었다''는 뜻이므로 ②는 stopped worrying이 되어야 한다. stop to worry는 ''걱정하기 위해 멈추었다''는 어색한 의미가 된다. ④는 ''(과거에) 외로웠던 것을 기억한다''는 뜻의 remember+동명사, ⑤는 ''(과거에) 전학한 것을 후회하지 않는다''는 regret+동명사로 모두 올바르다.'),
(34,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

We had fun ___ in the river last summer.','["fish", "to fish", "fishing", "fished", "to fishing"]'::jsonb,3,'「have fun+동명사」는 ''~하면서 즐거운 시간을 보내다''라는 뜻의 동명사 관용 표현이므로 fishing이 알맞다. have fun 뒤에 to부정사(to fish)나 동사원형(fish)을 쓸 수 없다는 점이 함정이다.'),
(34,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

I''m looking forward to ___ from you soon.','["hear", "heard", "hearing", "be heard", "hears"]'::jsonb,3,'look forward to에서 to는 전치사이므로 뒤에 동명사 hearing을 써야 한다. to를 to부정사로 착각하여 동사원형 hear를 쓰는 것이 가장 흔한 실수다.'),
(34,2,'어법','다음 중 어법상 <b>틀린</b> 문장은?','["She is busy preparing for the concert.", "This book is worth reading twice.", "I feel like eating something spicy tonight.", "He spent two hours to fix his computer.", "It is no use crying over spilled milk."]'::jsonb,4,'「spend+시간+동명사」 구문이므로 ④는 to fix가 아니라 fixing이 되어야 한다. be busy v-ing, be worth v-ing, feel like v-ing, It is no use v-ing는 모두 동명사를 쓰는 관용 표현으로 올바르게 쓰였다.'),
(34,2,'영작','다음 우리말을 영어로 옳게 옮긴 것은?

나는 그의 농담에 웃지 않을 수 없었다.','["I couldn''t help laugh at his joke.", "I couldn''t help to laugh at his joke.", "I couldn''t help laughing at his joke.", "I couldn''t help but laughing at his joke.", "I couldn''t stop to laugh at his joke."]'::jsonb,3,'''~하지 않을 수 없다''는 「cannot help+동명사」로 표현하므로 couldn''t help laughing이 옳다. ④의 cannot help but 뒤에는 동사원형(laugh)이 와야 하고, ②처럼 help 뒤에 to부정사를 쓰면 이 관용 표현이 성립하지 않는다.'),
(34,3,'밑줄어법','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

My grandfather is used to <u>getting</u>① up early. Every morning he goes <u>hiking</u>② in the hills near his house. He says the fresh air keeps him from <u>feeling</u>③ tired, and the exercise is worth <u>doing</u>④ every day. These days he is busy <u>to plant</u>⑤ vegetables in his garden.','["getting", "hiking", "feeling", "doing", "to plant"]'::jsonb,5,'「be busy+동명사」는 ''~하느라 바쁘다''라는 관용 표현이므로 ⑤는 to plant가 아니라 planting이 되어야 한다. ①은 be used to v-ing(~하는 데 익숙하다), ③은 keep A from v-ing(A가 ~하지 못하게 하다), ④는 be worth v-ing(~할 가치가 있다)로 모두 올바르다.'),
(35,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Look at the ___ baby on the sofa.','["sleep", "sleeping", "slept", "to sleep", "sleeps"]'::jsonb,2,'''잠자고 있는 아기''라는 능동·진행의 의미로 baby를 수식하므로 현재분사 sleeping이 알맞다. 과거분사 slept는 수동의 의미인데 아기가 ''잠재워지는'' 대상이 아니므로 틀린다.'),
(35,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

This is a novel ___ by Hemingway.','["write", "writing", "written", "wrote", "to writing"]'::jsonb,3,'소설은 헤밍웨이에 의해 ''쓰인'' 대상이므로 수동의 의미를 나타내는 과거분사 written이 알맞다. 현재분사 writing은 능동의 의미라서 ''소설이 쓰고 있는''이라는 어색한 뜻이 되어 틀린다.'),
(35,2,'빈칸짝','다음 두 문장의 빈칸에 들어갈 말이 순서대로 바르게 짝지어진 것은?

• The girl ___ the piano on stage is my sister.
• I got a letter ___ in French.','["playing – writing", "playing – written", "played – written", "played – writing", "to play – written"]'::jsonb,2,'첫 문장은 소녀가 피아노를 ''치고 있는'' 능동 관계이므로 현재분사 playing, 둘째 문장은 편지가 프랑스어로 ''쓰인'' 수동 관계이므로 과거분사 written을 쓴다. 분사가 뒤에 딸린 어구와 함께 명사를 뒤에서 수식하는 구조라는 점도 함께 확인해야 한다.'),
(35,2,'어법','다음 중 어법상 옳은 문장은?','["The boy waited outside is my cousin.", "The police found the stolen car yesterday.", "She kept me waited for an hour.", "There was a breaking window in the classroom.", "He sat surrounding by his fans."]'::jsonb,2,'②는 차가 ''도난당한'' 수동 관계이므로 과거분사 stolen이 car를 수식하는 올바른 문장이다. ①과 ③은 소년과 내가 ''기다리는'' 능동 주체이므로 waiting을 써야 하고, ④는 창문이 ''깨진'' 것이므로 broken, ⑤는 그가 팬들에게 ''둘러싸인'' 것이므로 surrounded를 써야 한다.'),
(35,3,'밑줄어법','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

The festival <u>held</u>① in our town every fall attracts many visitors. Last year, I watched a magician <u>performing</u>② tricks on the main stage. The crowd <u>gathered</u>③ around him couldn''t take their eyes off the show. A boy <u>standing</u>④ next to me kept shouting with joy, and even the balloons <u>floated</u>⑤ above the stage seemed to dance.','["held", "performing", "gathered", "standing", "floated"]'::jsonb,5,'풍선이 무대 위에 ''떠 있는'' 능동의 의미로 balloons를 수식하므로 ⑤는 과거분사 floated가 아니라 현재분사 floating이 되어야 한다. ①은 축제가 ''열리는'' 수동, ③은 군중이 ''모인'' 수동의 의미로 과거분사가 올바르고, ②는 지각동사 watched의 목적격 보어로 쓰인 현재분사다.'),
(36,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

The movie was so ___ that I fell asleep.','["bore", "boring", "bored", "to bore", "bores"]'::jsonb,2,'영화가 지루한 감정을 ''일으키는'' 주체이므로 현재분사 boring이 알맞다. bored는 감정을 ''느끼는'' 사람에게 쓰는 과거분사이므로 사물인 영화에는 쓸 수 없다.'),
(36,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

She was ___ to win first prize.','["surprise", "surprising", "surprised", "to surprise", "surprises"]'::jsonb,3,'그녀가 놀라움이라는 감정을 ''느끼는'' 대상이므로 과거분사 surprised가 알맞다. surprising은 놀라움을 ''일으키는'' 사물이나 일에 쓰는 현재분사이므로 사람의 감정 상태를 나타내는 이 문장에는 맞지 않는다.'),
(36,2,'빈칸짝','다음 두 문장의 빈칸에 들어갈 말이 순서대로 바르게 짝지어진 것은?

• The result of the experiment was quite ___.
• The scientists were ___ by the result.','["satisfying – satisfied", "satisfied – satisfying", "satisfying – satisfying", "satisfied – satisfied", "satisfy – satisfied"]'::jsonb,1,'실험 결과는 만족을 ''일으키는'' 주체이므로 현재분사 satisfying, 과학자들은 만족을 ''느끼는'' 대상이므로 과거분사 satisfied를 쓴다. 감정동사의 분사는 감정을 유발하면 현재분사, 감정을 느끼면 과거분사라는 원칙을 두 빈칸 모두에 적용해야 한다.'),
(36,2,'어법','다음 중 어법상 <b>틀린</b> 문장은?','["The news was shocking to everyone.", "I was confused by the complicated instructions.", "Playing the same game every day is tired.", "The excited fans ran toward the singer.", "Her speech was moving, and many people cried."]'::jsonb,3,'매일 같은 게임을 하는 것은 피곤함을 ''일으키는'' 일이므로 ③은 tired가 아니라 tiring이 되어야 한다. ④의 excited는 흥분을 ''느낀'' 팬들을 수식하는 과거분사로 올바르고, ①과 ⑤는 감정을 유발하는 주체에 현재분사를 쓴 옳은 문장이다.'),
(36,3,'밑줄어법','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

Last weekend I visited an art museum. The exhibition was more <u>interesting</u>① than I had expected. I was especially <u>fascinated</u>② by a painting of a dancing woman. Some visitors looked <u>boring</u>③ and left early, but I stayed until closing time. It was a really <u>satisfying</u>④ experience, and I felt <u>refreshed</u>⑤ afterwards.','["interesting", "fascinated", "boring", "satisfying", "refreshed"]'::jsonb,3,'방문객들은 지루함을 ''느끼는'' 사람들이므로 ③은 boring이 아니라 bored가 되어야 한다. looked boring이면 ''방문객들이 (남을) 지루하게 하는 것처럼 보였다''는 다른 의미가 된다. ②와 ⑤는 감정을 느끼는 사람 주어에 과거분사를 쓴 올바른 표현이다.'),
(37,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

___ tired, she went to bed early.','["Feel", "Felt", "Feeling", "To feeling", "Feels"]'::jsonb,3,'''피곤함을 느꼈기 때문에''라는 이유를 나타내는 분사구문으로, 주어 she가 느끼는 능동 관계이므로 현재분사 Feeling이 알맞다. 과거분사 Felt를 쓰면 수동의 의미가 되어 문맥에 맞지 않는다.'),
(37,1,'문장전환','다음 문장을 분사구문으로 바꿀 때 빈칸에 들어갈 말로 가장 적절한 것은?

While he was walking along the beach, he found a strange shell.
= ___ along the beach, he found a strange shell.','["Walk", "Walking", "Walked", "To walking", "Being walk"]'::jsonb,2,'부사절의 접속사와 주어를 없애고 동사를 현재분사로 바꾸면 분사구문이 되므로 Walking이 알맞다. 주어 he가 ''걷는'' 능동 관계이므로 과거분사 Walked는 쓸 수 없다.'),
(37,2,'문장전환','다음 문장을 분사구문으로 바르게 바꾼 것은?

Because she didn''t know his phone number, she couldn''t call him.','["Knowing not his phone number, she couldn''t call him.", "Not knowing his phone number, she couldn''t call him.", "Don''t knowing his phone number, she couldn''t call him.", "Not known his phone number, she couldn''t call him.", "Because not knowing his phone number, she couldn''t call him."]'::jsonb,2,'분사구문의 부정은 분사 바로 앞에 Not을 붙이므로 Not knowing이 옳다. ①은 부정어의 위치가 틀렸고, ④는 주어 she가 ''아는'' 능동 관계인데 과거분사를 써서 틀렸다.'),
(37,2,'빈칸짝','다음 문장의 빈칸에 들어갈 말이 순서대로 바르게 짝지어진 것은?

She watched TV, ___ on the couch with her cat ___ beside her.','["lying – sleeping", "lying – slept", "lain – sleeping", "laying – slept", "lied – sleeping"]'::jsonb,1,'첫 빈칸은 ''소파에 누운 채''라는 부대상황의 분사구문으로 lie(눕다)의 현재분사 lying을 쓰고, 둘째 빈칸은 「with+명사+분사」 구문에서 고양이가 ''자고 있는'' 능동 관계이므로 현재분사 sleeping을 쓴다. laying은 ''~을 놓다''라는 타동사 lay의 분사형이라 목적어가 없는 이 문장에는 맞지 않는다.'),
(37,3,'밑줄어법','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

<u>Arriving</u>① at the station, I found that the train had already left. <u>Not having</u>② enough money for a taxi, I decided to walk home. <u>Walking</u>③ down the quiet street, I heard someone calling my name. <u>Turning</u>④ around, I saw my old friend running toward me, <u>waved</u>⑤ his hand excitedly.','["Arriving", "Not having", "Walking", "Turning", "waved"]'::jsonb,5,'''손을 흔들면서''라는 부대상황을 나타내는 분사구문으로, 친구가 손을 흔드는 능동 관계이므로 ⑤는 waved가 아니라 waving이 되어야 한다. ②는 분사 앞에 Not을 붙인 분사구문의 부정으로 올바르고, ①·③·④는 모두 능동 관계의 현재분사 분사구문으로 맞다.'),
(38,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Hurry up, ___ you will miss the school bus.','["and", "but", "or", "so", "nor"]'::jsonb,3,'명령문 뒤의 「or」는 ''그렇지 않으면''의 의미로, ''서둘러라, 그렇지 않으면 버스를 놓칠 것이다''가 되어 자연스럽다. ① and는 ''그러면''의 의미라 ''서두르면 버스를 놓친다''는 어색한 뜻이 되고, ④ so는 명령문과 결과를 이렇게 연결할 수 없다.'),
(38,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

She can speak not only English ___ also Chinese.','["and", "or", "so", "but", "nor"]'::jsonb,4,'「not only A but also B」는 ''A뿐만 아니라 B도''라는 뜻의 상관접속사로, 빈칸에는 but이 와야 한다. ① and나 ② or를 쓰면 상관접속사 구문이 성립하지 않는다.'),
(38,2,'어법','다음 중 어법상 옳은 문장은?

① He is both kind or generous.
② You can drink either juice nor milk.
③ The movie was not sad but touching.
④ She likes neither pizza or pasta.
⑤ Not only Jim but also his friends was invited to the party.','["He is both kind or generous.", "You can drink either juice nor milk.", "The movie was not sad but touching.", "She likes neither pizza or pasta.", "Not only Jim but also his friends was invited to the party."]'::jsonb,3,'「not A but B」(A가 아니라 B)가 올바르게 쓰인 ③이 정답이다. ①은 both A and B, ②는 either A or B, ④는 neither A nor B가 되어야 하며, ⑤는 not only A but also B에서 동사가 B(his friends)에 일치해야 하므로 was가 아니라 were가 되어야 한다.'),
(38,2,'영작','다음 우리말을 영어로 바르게 옮긴 것은?

일찍 출발해라, 그러면 첫 기차를 탈 수 있을 것이다.','["Leave early, or you will catch the first train.", "Leave early, and you will catch the first train.", "Leave early, and you will miss the first train.", "Leave early, or you must catch the first train.", "Left early, and you will catch the first train."]'::jsonb,2,'「명령문, and ~」는 ''…해라, 그러면 ~할 것이다''라는 뜻이므로 ②가 우리말과 일치한다. ①의 or는 ''그렇지 않으면''이라는 반대 의미가 되고, ⑤는 명령문 자리에 과거형 Left를 써서 어법상 틀렸다.'),
(38,3,'어법(밑줄)','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

Mina wanted to buy a birthday gift for her mother, <u>so</u>① she went to the mall. A silk scarf caught her eye, <u>but</u>② it was too expensive. She had to choose either the scarf <u>nor</u>③ a smaller present. In the end, she picked a hat, <u>and</u>④ her mother loved it. Not only the color <u>but also</u>⑤ the design matched her mother''s style.','["so", "but", "nor", "and", "but also"]'::jsonb,3,'상관접속사 「either A or B」 구문이므로 ③의 nor는 or로 고쳐야 한다. nor는 neither와 짝을 이루는 접속사이다. ①의 so(그래서), ②의 but(그러나), ⑤의 not only A but also B는 모두 문맥과 어법에 맞게 쓰였다.'),
(39,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

I don''t know ___ or not she will come to the party.','["that", "if", "what", "whether", "because"]'::jsonb,4,'''~인지 아닌지''를 뜻하며 바로 뒤에 or not을 붙일 수 있는 접속사는 whether이다. ② if도 ''~인지''의 뜻으로 쓰이지만 「if or not」처럼 or not을 바로 뒤에 붙여 쓸 수 없다.'),
(39,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

I believe ___ he will keep his promise.','["what", "that", "whether", "who", "if"]'::jsonb,2,'believe의 목적어로 완전한 문장(he will keep his promise)이 이어지므로 명사절 접속사 that이 알맞다. ① what 뒤에는 불완전한 문장이 와야 하고, believe는 ③ whether나 ⑤ if가 이끄는 ''~인지'' 의문의 절을 목적어로 취하지 않는다.'),
(39,2,'어법','다음 중 어법상 옳은 문장은?

① I wonder what time is it now.
② Do you know where does he live?
③ She asked me what did I want for lunch.
④ Can you tell me when the movie starts?
⑤ I don''t know why was he so angry.','["I wonder what time is it now.", "Do you know where does he live?", "She asked me what did I want for lunch.", "Can you tell me when the movie starts?", "I don''t know why was he so angry."]'::jsonb,4,'간접의문문은 「의문사+주어+동사」의 어순을 취하므로 when the movie starts로 쓴 ④가 옳다. ①은 what time it is, ②는 where he lives, ③은 what I wanted, ⑤는 why he was로 각각 고쳐야 하며, 간접의문문 안에서 do/does/did나 도치를 쓰면 안 된다.'),
(39,2,'문장연결','다음 두 문장을 한 문장으로 바르게 연결한 것은?

Do you think? + Who broke the window?','["Do you think who broke the window?", "Do you think who did break the window?", "Who do you think broke the window?", "Who do you think did he break the window?", "Who you think broke the window?"]'::jsonb,3,'주절의 동사가 think, believe, guess 등 생각을 나타내는 동사일 때 간접의문문의 의문사는 문장 맨 앞으로 나가므로 ③이 옳다. ①처럼 의문사를 뒤에 두면 Yes/No로 답하는 어색한 문장이 되고, ④는 조동사 did와 주어를 중복 사용하여 틀렸다.'),
(39,3,'어법(밑줄)','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

Scientists wondered <u>whether dolphins could recognize</u>① themselves in a mirror. Many experts believed <u>that these animals were</u>② smart enough. A reporter asked the team <u>how did the dolphins react</u>③ to their own reflection. The team explained <u>that the dolphins touched</u>④ the marks on their bodies. It is now clear <u>that dolphins know</u>⑤ the mirror image is their own.','["whether dolphins could recognize", "that these animals were", "how did the dolphins react", "that the dolphins touched", "that dolphins know"]'::jsonb,3,'③은 asked의 목적어인 간접의문문이므로 「의문사+주어+동사」 어순인 how the dolphins reacted로 고쳐야 한다. 간접의문문에서는 조동사 did를 쓰지 않는다. ①의 whether(~인지)와 ②④⑤의 명사절 접속사 that은 모두 완전한 절을 이끌어 어법상 옳다.'),
(40,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

___ it was raining heavily, we canceled the picnic.','["Because", "Though", "If", "Unless", "Whether"]'::jsonb,1,'''비가 심하게 내렸기 때문에 소풍을 취소했다''는 인과 관계이므로 이유의 접속사 Because가 알맞다. ② Though(비록 ~이지만)를 쓰면 ''비가 오는데도 취소했다''는 어색한 의미가 된다.'),
(40,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

___ he is only ten years old, he is very wise.','["Because", "If", "Although", "Until", "So"]'::jsonb,3,'''겨우 열 살이지만 매우 지혜롭다''는 양보의 의미이므로 Although(비록 ~이지만)가 알맞다. ① Because를 쓰면 ''열 살이기 때문에 지혜롭다''는 어색한 인과 관계가 된다.'),
(40,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

We will go hiking if it ___ sunny tomorrow.','["will be", "is", "was", "were", "be"]'::jsonb,2,'조건을 나타내는 부사절에서는 미래의 일이라도 현재시제로 미래를 대신하므로 is가 정답이다. ① will be는 tomorrow에 이끌려 고르기 쉬운 함정으로, 조건 부사절 안에서는 will을 쓸 수 없다. ④ were는 가정법 과거인데 주절이 will이므로 맞지 않는다.'),
(40,2,'어법','다음 중 어법상 옳은 문장은?

① Unless you don''t leave now, you will miss the train.
② I will call you when I will arrive at the airport.
③ Though she was tired, but she finished her homework.
④ He was late because of the traffic was heavy.
⑤ While I was taking a shower, the phone rang.','["Unless you don''t leave now, you will miss the train.", "I will call you when I will arrive at the airport.", "Though she was tired, but she finished her homework.", "He was late because of the traffic was heavy.", "While I was taking a shower, the phone rang."]'::jsonb,5,'시간의 접속사 While이 부사절을 바르게 이끄는 ⑤가 정답이다. ①의 Unless는 이미 부정(if ~ not)의 의미이므로 don''t와 함께 쓸 수 없고, ②는 시간 부사절에서 will을 쓸 수 없으며, ③은 Though와 but을 중복 사용했고, ④의 because of 뒤에는 절이 아니라 명사(구)가 와야 한다.'),
(40,3,'어법(밑줄)','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

The city festival opens this Friday. <u>If</u>① the weather stays clear, over a thousand visitors will come. The organizers will hand out free raincoats <u>in case</u>② it rains. <u>Although</u>③ the tickets are not cheap, they are selling fast. The fireworks will start as soon as the sun <u>will set</u>④, and the food trucks will stay open until the last visitor <u>leaves</u>⑤.','["If", "in case", "Although", "will set", "leaves"]'::jsonb,4,'as soon as가 이끄는 시간의 부사절에서는 현재시제가 미래를 대신하므로 ④ will set은 sets로 고쳐야 한다. ⑤의 leaves는 until이 이끄는 시간 부사절에서 현재시제를 바르게 쓴 것이고, ①~③의 접속사들도 문맥에 맞게 쓰였다.'),
(41,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

I have a friend ___ lives in Busan.','["who", "whom", "whose", "which", "what"]'::jsonb,1,'선행사 a friend가 사람이고 빈칸이 관계사절의 주어 자리이므로 주격 관계대명사 who가 알맞다. ② whom은 목적격이라 주어 자리에 쓸 수 없고, ④ which는 선행사가 사물일 때 쓴다.'),
(41,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Look at the house ___ has a red roof.','["who", "whom", "whose", "which", "what"]'::jsonb,4,'선행사 the house가 사물이고 빈칸 뒤에 동사 has가 바로 이어지는 주어 자리이므로 주격 관계대명사 which가 알맞다. ① who는 사람 선행사에 쓰고, ⑤ what은 선행사를 포함하므로 선행사가 이미 있는 문장에는 쓸 수 없다.'),
(41,2,'어법','다음 중 어법상 틀린 문장은?

① She has a cat that follows her everywhere.
② The man who is standing at the gate is my uncle.
③ I bought a phone which have a great camera.
④ Do you know the girl who won the contest?
⑤ This is the bus that goes to the museum.','["She has a cat that follows her everywhere.", "The man who is standing at the gate is my uncle.", "I bought a phone which have a great camera.", "Do you know the girl who won the contest?", "This is the bus that goes to the museum."]'::jsonb,3,'주격 관계대명사절의 동사는 선행사에 수를 일치시켜야 하는데, ③의 선행사 a phone은 단수이므로 have가 아니라 has를 써야 한다. 나머지 문장들은 선행사와 관계대명사의 격, 동사의 수 일치가 모두 올바르다.'),
(41,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Look at the boy and his dog ___ are running across the field.','["who", "which", "whom", "that", "whose"]'::jsonb,4,'선행사가 「사람+동물」(the boy and his dog)일 때는 관계대명사 that을 쓰는 것이 원칙이다. ① who는 사람만, ② which는 사물이나 동물만 선행사로 취하므로 둘이 섞인 선행사에는 쓸 수 없다.'),
(41,3,'어법(밑줄)','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

Our town has a volunteer club <u>that cleans</u>① the river every Sunday. Anyone <u>who is</u>② interested can join. The club has thirty members <u>who come</u>③ from different schools. The leader is a nurse <u>who works</u>④ at the city hospital. She welcomes every student <u>who want</u>⑤ to protect the environment.','["that cleans", "who is", "who come", "who works", "who want"]'::jsonb,5,'주격 관계대명사절의 동사는 선행사에 수를 일치시켜야 하는데, ⑤의 선행사 every student는 단수이므로 want가 아니라 wants를 써야 한다. ①~④는 각각 단수 선행사에는 단수 동사, 복수 선행사(thirty members)에는 복수 동사를 바르게 썼다.'),
(42,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

This is the book ___ I bought at the airport yesterday.','["who", "whom", "whose", "which", "what"]'::jsonb,4,'선행사 the book이 사물이고 빈칸은 bought의 목적어 자리이므로 목적격 관계대명사 which가 알맞다. ② whom은 선행사가 사람일 때 쓰고, ⑤ what은 선행사가 있는 문장에는 쓸 수 없다.'),
(42,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

I met a girl ___ father is a pilot.','["who", "whom", "whose", "which", "that"]'::jsonb,3,'''그녀의 아버지''(her father)라는 소유 관계를 나타내며 뒤의 명사 father를 수식하므로 소유격 관계대명사 whose가 알맞다. ① who나 ⑤ that을 쓰면 뒤의 명사 father와 연결되지 않아 문장이 성립하지 않는다.'),
(42,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

___ I want for my birthday is a new bicycle.','["That", "Which", "Who", "What", "Whether"]'::jsonb,4,'빈칸이 이끄는 절에서 want의 목적어가 빠져 있는 불완전한 문장이므로, 선행사를 포함하는 관계대명사 What(~하는 것)이 알맞다. ① That은 접속사로 쓰이면 뒤에 완전한 문장이 와야 하므로 목적어가 없는 이 문장에는 쓸 수 없다.'),
(42,2,'어법','다음 중 어법상 틀린 문장은?

① The movie which we watched last night was boring.
② This is the house what my grandfather built.
③ She is the singer whom I like most.
④ I have a friend whose brother is a famous chef.
⑤ He showed me the pictures that he took in Paris.','["The movie which we watched last night was boring.", "This is the house what my grandfather built.", "She is the singer whom I like most.", "I have a friend whose brother is a famous chef.", "He showed me the pictures that he took in Paris."]'::jsonb,2,'관계대명사 what은 선행사를 포함하므로 the house라는 선행사가 이미 있는 ②에는 쓸 수 없고, which나 that으로 고쳐야 한다. ①③⑤는 목적격 관계대명사, ④는 소유격 관계대명사가 바르게 쓰인 문장이다.'),
(42,3,'어법(밑줄)','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

The novel <u>that I read</u>① last month changed <u>what I think</u>② about friendship. Its author, a woman <u>whose childhood</u>③ was lonely, wrote about a boy <u>whom helps</u>④ his elderly neighbor. The small acts of kindness <u>which the boy shows</u>⑤ moved many readers.','["that I read", "what I think", "whose childhood", "whom helps", "which the boy shows"]'::jsonb,4,'④는 바로 뒤에 동사 helps가 이어지는 주어 자리이므로 목적격 whom이 아니라 주격 관계대명사 who를 써야 한다. ①과 ⑤는 목적격 관계대명사, ②는 선행사를 포함한 what, ③은 소유격 whose가 모두 바르게 쓰였다.'),
(43,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

This is the town ___ I was born.','["which", "where", "when", "why", "how"]'::jsonb,2,'선행사 the town이 장소이고 뒤에 완전한 문장(I was born)이 이어지므로 관계부사 where가 알맞다. ① which를 쓰려면 뒤 문장에 목적어나 주어가 빠져 있거나 in which처럼 전치사가 필요하다.'),
(43,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Do you remember the day ___ we first met?','["where", "which", "when", "why", "how"]'::jsonb,3,'선행사 the day가 시간을 나타내고 뒤에 완전한 문장이 이어지므로 관계부사 when이 알맞다. ② which를 쓰려면 met의 주어나 목적어가 빠져 있어야 하는데 이 문장은 완전하므로 쓸 수 없다.'),
(43,2,'빈칸','다음 두 문장의 빈칸에 들어갈 말이 순서대로 바르게 짝지어진 것은?

• This is the restaurant ___ we had dinner last week.
• This is the restaurant ___ my uncle opened last year.','["where – where", "which – where", "where – which", "which – which", "when – which"]'::jsonb,3,'첫 번째 문장은 뒤에 완전한 문장이 이어지므로 관계부사 where를, 두 번째 문장은 opened의 목적어가 빠진 불완전한 문장이므로 관계대명사 which를 써야 한다. 선행사가 장소라도 관계사절이 불완전하면 관계부사가 아닌 관계대명사를 쓴다는 점이 핵심이다.'),
(43,2,'어법','다음 중 어법상 틀린 문장은?

① Tell me the reason why you were late.
② I remember the day when we went camping together.
③ Seoul is the city where I grew up.
④ This is the way how she solved the problem.
⑤ Do you know the time when the store opens?','["Tell me the reason why you were late.", "I remember the day when we went camping together.", "Seoul is the city where I grew up.", "This is the way how she solved the problem.", "Do you know the time when the store opens?"]'::jsonb,4,'선행사 the way와 관계부사 how는 함께 쓸 수 없으므로 ④는 This is the way she solved ~ 또는 This is how she solved 중 하나로 써야 한다. 나머지는 이유(why), 시간(when), 장소(where)의 관계부사가 선행사와 바르게 짝지어져 있다.'),
(43,3,'어법(밑줄)','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

My grandmother often talks about the village <u>where she grew up</u>①. She remembers the day <u>when electricity first came</u>② to her town. She once explained <u>how people stored</u>③ food without refrigerators. That is the reason <u>why she never wastes</u>④ anything. To her, the kitchen was the place <u>which the whole family gathered</u>⑤ every evening.','["where she grew up", "when electricity first came", "how people stored", "why she never wastes", "which the whole family gathered"]'::jsonb,5,'⑤는 선행사 the place 뒤에 완전한 문장(the whole family gathered)이 이어지므로 관계대명사 which가 아니라 관계부사 where를 써야 한다. which를 쓰려면 gathered 뒤에 목적어 자리가 비어 있어야 한다. ①~④는 장소, 시간, 방법, 이유의 관계부사가 모두 바르게 쓰였다.'),
(44,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

I have two brothers, ___ live in Seoul.','["that", "which", "who", "whose", "what"]'::jsonb,3,'콤마 뒤에 이어지는 계속적 용법이고 선행사 two brothers가 사람이므로 who가 알맞다. ① that은 계속적 용법으로 쓸 수 없다는 것이 핵심이며, ② which는 선행사가 사물일 때 쓴다.'),
(44,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

She gave me a book, ___ was very interesting.','["that", "who", "what", "whose", "which"]'::jsonb,5,'선행사 a book이 사물이고 콤마 뒤의 계속적 용법이므로 which가 알맞다. ① that은 계속적 용법에 쓸 수 없고, ③ what은 선행사를 포함하는 관계대명사이므로 선행사가 있는 이 문장에 쓸 수 없다.'),
(44,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

He passed the difficult exam, ___ made his parents very proud.','["that", "what", "who", "which", "whom"]'::jsonb,4,'콤마 뒤의 which는 계속적 용법으로 쓰여 앞 문장 전체(그가 어려운 시험에 합격한 것)를 선행사로 받을 수 있다. ① that은 계속적 용법에 쓸 수 없고, ② what은 선행사를 포함하므로 앞 내용을 받는 이 자리에 쓸 수 없다.'),
(44,2,'어법','다음 중 어법상 옳은 문장은?

① My uncle, that lives in Jeju, is a fisherman.
② He said nothing, which made me more nervous.
③ She bought a new bag, that was very expensive.
④ I met Jane, whom is my old classmate.
⑤ The book, what I borrowed from her, was really fun.','["My uncle, that lives in Jeju, is a fisherman.", "He said nothing, which made me more nervous.", "She bought a new bag, that was very expensive.", "I met Jane, whom is my old classmate.", "The book, what I borrowed from her, was really fun."]'::jsonb,2,'계속적 용법의 which가 앞 문장 전체를 받아 ''그가 아무 말도 하지 않은 것이 나를 더 초조하게 했다''는 의미를 만드는 ②가 옳다. ①③은 계속적 용법에 that을 쓸 수 없어 틀렸고, ④는 주어 자리이므로 whom이 아닌 who, ⑤는 선행사가 있으므로 what이 아닌 which를 써야 한다.'),
(44,3,'어법(밑줄)','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

Last summer I visited Rome, <u>where I stayed</u>① for a week. My guide, <u>who spoke</u>② perfect English, showed me the Colosseum, <u>that was built</u>③ about 2,000 years ago. In the afternoon I tried gelato, <u>which tasted</u>④ amazing. The trip ended too soon, <u>which made</u>⑤ me a little sad.','["where I stayed", "who spoke", "that was built", "which tasted", "which made"]'::jsonb,3,'관계대명사 that은 콤마 뒤의 계속적 용법으로 쓸 수 없으므로 ③은 which was built로 고쳐야 한다. ①은 계속적 용법의 관계부사 where, ②는 사람 선행사를 받는 who, ⑤는 앞 문장 전체를 받는 which로 모두 바르게 쓰였다.'),
(45,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

If I ___ rich, I would travel around the world.','["am", "is", "were", "will be", "have been"]'::jsonb,3,'주절에 「would+동사원형」이 쓰인 가정법 과거 문장으로, 현재 사실과 반대되는 상황을 가정하므로 be동사는 인칭에 관계없이 were를 쓴다. ① am을 쓰면 단순 조건문이 되어 주절의 would와 어울리지 않는다.'),
(45,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

I wish I ___ a car now.','["have", "has", "will have", "had", "am having"]'::jsonb,4,'「I wish+가정법 과거」는 현재 이룰 수 없는 소망(지금 차가 있으면 좋을 텐데)을 나타내므로 과거형 had를 쓴다. ① have처럼 현재형을 쓰면 가정법이 성립하지 않는다.'),
(45,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

If she ___ harder, she would have passed the exam.','["studies", "had studied", "studied", "has studied", "would have studied"]'::jsonb,2,'주절에 「would have+과거분사」가 쓰였으므로 과거 사실과 반대되는 가정법 과거완료이며, if절에는 「had+과거분사」를 써야 한다. ③ studied는 가정법 과거로, 주절이 would pass일 때 쓰는 형태이므로 함정이다.'),
(45,2,'영작','다음 우리말을 영어로 바르게 옮긴 것은?

그는 마치 그 사고를 직접 봤던 것처럼 말한다.

→ He talks ___.','["as if he sees the accident himself", "as if he saw the accident himself", "as if he had seen the accident himself", "as if he has seen the accident himself", "as if he would see the accident himself"]'::jsonb,3,'말하는 시점(현재)보다 이전인 과거의 일을 반대로 가정하므로 「as if+가정법 과거완료(had+과거분사)」를 쓴다. ② saw는 가정법 과거로 주절과 같은 시점(마치 지금 보는 것처럼)을 가정할 때 쓰므로 ''봤던 것처럼''이라는 우리말과 맞지 않는다.'),
(45,3,'어법(밑줄)','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

If I <u>had known</u>① about the concert earlier, I <u>would have bought</u>② the tickets right away. My sister acts <u>as if she were</u>③ not disappointed, but I know she is. I wish we <u>could go</u>④ together next time. If the tickets <u>will be</u>⑤ cheaper, more students could enjoy live music.','["had known", "would have bought", "as if she were", "could go", "will be"]'::jsonb,5,'마지막 문장은 주절에 could enjoy가 쓰인 가정법 과거이므로 if절의 ⑤ will be는 were로 고쳐야 한다. ①②는 가정법 과거완료의 if절과 주절, ③은 as if 가정법 과거, ④는 I wish 가정법 과거로 모두 바르게 쓰였다.'),
(46,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

Each of the students ___ a tablet PC.','["have", "has", "are", "were", "do"]'::jsonb,2,'「each of+복수명사」는 단수 취급하므로 단수 동사 has를 써야 한다. ① have는 바로 앞의 복수명사 the students에 이끌려 고르기 쉬운 함정이다.'),
(46,1,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

She said that she ___ busy then.','["is", "are", "was", "were", "will be"]'::jsonb,3,'주절의 동사 said가 과거이므로 시제 일치에 따라 종속절의 동사도 과거형 was를 써야 한다. ① is는 시제 일치에 어긋나고, ④ were는 주어 she와 수가 맞지 않는다.'),
(46,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

The number of foreign tourists ___ increasing every year.','["is", "are", "were", "have", "do"]'::jsonb,1,'「the number of+복수명사」는 ''~의 수''라는 뜻으로 단수 취급하므로 is가 알맞다. ② are는 복수명사 tourists에 이끌린 함정으로, ''많은 ~''이라는 뜻의 「a number of+복수명사」일 때만 복수 동사를 쓴다.'),
(46,2,'빈칸','다음 빈칸에 들어갈 말로 가장 적절한 것은?

The teacher said that the Earth ___ around the Sun.','["go", "went", "had gone", "goes", "has gone"]'::jsonb,4,'지구가 태양 주위를 돈다는 것은 불변의 진리이므로 주절의 시제와 관계없이 항상 현재시제 goes를 쓴다. ② went는 주절의 said에 맞춰 시제 일치를 적용한 함정으로, 불변의 진리는 시제 일치의 예외에 해당한다.'),
(46,3,'어법(밑줄)','다음 글의 밑줄 친 부분 중 어법상 틀린 것은?

The results of the survey <u>show</u>① that most teenagers <u>sleep</u>② less than seven hours a night. Our teacher told us that enough sleep <u>was</u>③ important for memory, and she added that the brain <u>organizes</u>④ memories during deep sleep. The number of students who fall asleep in class <u>are</u>⑤ increasing.','["show", "sleep", "was", "organizes", "are"]'::jsonb,5,'주어가 「the number of+복수명사」이면 단수 취급하므로 ⑤ are는 is로 고쳐야 한다. ①은 복수 주어 The results에 맞는 복수 동사이고, ③은 주절 told에 따른 시제 일치, ④는 일반적 사실을 나타내는 현재시제로 모두 어법에 맞다.');
