-- ============================================================
-- 내신문법 통합대비 실전 TEST 1~5회 — Supabase 세팅
-- Supabase SQL Editor에서 한 번만 실행 (grammar_* 스키마가 이미 있어야 함)
-- ============================================================

-- 1) 서술형 문항 / 서술형 답안 테이블
create table if not exists grammar_written_questions (
  id serial primary key,
  test_id int not null references grammar_tests(id),
  seq int not null,                 -- 시험지 내 번호 (15~20)
  unit_no int not null,
  stem text not null,
  blanks jsonb not null default '[]'::jsonb,   -- 답안 입력 칸 라벨
  model_answer text not null,
  points int not null default 7,
  explanation text not null default ''
);
create index if not exists gwq_test_idx on grammar_written_questions(test_id);

create table if not exists grammar_written_answers (
  id serial primary key,
  attempt_id int not null references grammar_attempts(id) on delete cascade,
  wq_id int not null references grammar_written_questions(id),
  answer text,
  score int,                        -- null = 미채점
  graded_at timestamptz
);
create index if not exists gwa_attempt_idx on grammar_written_answers(attempt_id);
create unique index if not exists gwa_attempt_wq on grammar_written_answers(attempt_id, wq_id);

alter table grammar_written_questions enable row level security;
alter table grammar_written_answers enable row level security;
drop policy if exists gwq_read on grammar_written_questions;
create policy gwq_read on grammar_written_questions for select using (true);
drop policy if exists gwa_read on grammar_written_answers;
create policy gwa_read on grammar_written_answers for select using (true);
drop policy if exists gwa_write on grammar_written_answers;
create policy gwa_write on grammar_written_answers for insert with check (true);
drop policy if exists gwa_update on grammar_written_answers;
create policy gwa_update on grammar_written_answers for update using (true);

-- 2) 객관식 문항 (id 9001~) — 재실행 대비 삭제 후 삽입
delete from grammar_attempt_items where question_id between 9001 and 9500;
delete from grammar_written_answers where wq_id between 9501 and 10000;
delete from grammar_written_questions where id between 9501 and 10000;
delete from grammar_attempts where test_id between 901 and 950;
delete from grammar_tests where id between 901 and 950;
delete from grammar_questions where id between 9001 and 9500;


insert into grammar_questions (id, unit_no, level, qtype, stem, choices, answer, explanation, active) values
(9001,15,2,'지문 어법','다음 글의 밑줄 친 ⓐ~ⓔ 중 어법상 <u>틀린</u> 것의 개수는?

Last Saturday, someone ⓐ <u>threw</u> a cake at the famous painting in the museum. There ⓑ <u>was</u> four eyewitnesses. One of them, Ann, said, "I ⓒ <u>was looking</u> at the painting, and an old man ⓓ <u>was standing</u> in front of a wheelchair. He was much ⓔ <u>taller than</u> me."','["0개","1개","2개","3개","4개"]'::jsonb,2,'ⓑ four eyewitnesses(복수) → were. ⓐ throw–threw, ⓒⓓ 과거진행형, ⓔ much + 비교급 + than은 모두 옳다. (동아 5과 변형 지문)',true),
(9002,5,2,'어법 개수','다음 중 어법상 옳은 문장의 개수는?

ⓐ Each of the boys have his own locker.
ⓑ The number of students in our school is decreasing.
ⓒ Neither my parents nor my sister were at home.
ⓓ Every student and teacher was invited to the party.
ⓔ A number of tourists visits Jeju every year.
ⓕ Mathematics and physics are my favorite subjects.','["1개","2개","3개","4개","5개"]'::jsonb,3,'ⓐ each of + 복수명사 → 단수 has. ⓒ neither A nor B는 B(my sister)에 수일치 → was. ⓔ a number of + 복수명사 → 복수 visit. 옳은 것은 ⓑ(the number of → 단수), ⓓ(every ~ → 단수), ⓕ(A and B → 복수) 3개.',true),
(9003,20,2,'빈칸 짝짓기','다음 빈칸 (A)~(C)에 들어갈 말이 바르게 짝지어진 것은?

· Look! The kids (A)[play / are playing] soccer in the rain.
· She (B)[has / is having] two cats and a dog.
· We (C)[leave / are leaving] for Jeju at 7 tomorrow, so go to bed early.','["play – has – leave","are playing – has – are leaving","are playing – is having – leave","play – is having – are leaving","are playing – has – leave"]'::jsonb,2,'(A) Look!과 함께 지금 진행 중인 동작 → 현재진행형. (B) ''소유''의 have는 진행형 불가 → has. (C) 확정된 가까운 미래 계획은 현재진행형으로 표현할 수 있다 → are leaving.',true),
(9004,5,2,'대화 어법','다음 대화의 밑줄 친 ①~⑤ 중 어법상 <u>틀린</u> 것은?

A: ① <u>Is there</u> any milk in the fridge?
B: No, ② <u>there isn''t</u>. But ③ <u>there are</u> some juice and a few apples.
A: Then ④ <u>there is</u> no milk for my cereal.
B: Don''t worry. ⑤ <u>There is</u> a new cafe near our house. Let''s have breakfast there.','["①","②","③","④","⑤"]'::jsonb,3,'There is/are 뒤에 A and B가 오면 첫 번째 명사에 수일치한다. some juice(불가산) → there is some juice and a few apples.',true),
(9005,18,2,'어법 판단','다음 중 밑줄 친 부분의 과거형이 <u>모두</u> 바르게 쓰인 것은?','["She <u>lay</u> on the bed and <u>fell</u> asleep.","He <u>laid</u> the baby down and <u>lied</u> on the sofa.","We <u>rised</u> early and <u>rode</u> to the beach.","The bird <u>flew</u> away when the cat <u>catched</u> the mouse.","They <u>brang</u> food and <u>ate</u> together."]'::jsonb,1,'lie(눕다)–lay, fall–fell (O). ② lie(눕다)의 과거형은 lay (lied는 ''거짓말하다''의 과거형). ③ rise–rose. ④ catch–caught. ⑤ bring–brought.',true),
(9006,24,2,'영작 판단','다음 우리말을 영어로 옮길 때 어법상 옳은 것은?

너는 오늘 밤에 늦게까지 깨어 있어서는 안 된다. 내일 아침 일찍 떠날 예정이니까.','["You should not stay up late tonight. You are going to leave early tomorrow morning.","You don''t should stay up late tonight. You are going to leaving early tomorrow morning.","You shouldn''t to stay up late tonight. You will going to leave early tomorrow morning.","You should not stay up late tonight. You are going leave early tomorrow morning.","You not should stay up late tonight. You is going to leave early tomorrow morning."]'::jsonb,1,'조동사 부정: should not + 동사원형. be going to + 동사원형, 주어 You → are.',true),
(9007,32,2,'어법 판단','다음 <보기>의 밑줄 친 부분과 같이 동명사(명사 역할)로 쓰인 것을 <u>모두</u> 고른 것은?

<보기> His only hobby is <u>collecting</u> old coins.
ⓐ She is <u>collecting</u> data for her report.
ⓑ My goal this year is <u>reading</u> fifty books.
ⓒ The man <u>reading</u> a newspaper is my uncle.
ⓓ <u>Keeping</u> a diary in English is not easy.
ⓔ We are <u>keeping</u> the secret from him.','["ⓐ, ⓔ","ⓑ, ⓓ","ⓑ, ⓒ","ⓐ, ⓑ, ⓓ","ⓒ, ⓓ, ⓔ"]'::jsonb,2,'<보기>는 동명사 보어. ⓑ 동명사 보어, ⓓ 동명사 주어로 명사 역할. ⓐⓔ는 현재진행형, ⓒ는 명사를 수식하는 현재분사.',true),
(9008,28,2,'문장 전환','다음 문장의 전환이 어법상 옳지 <u>않은</u> 것은?','["To swim in this river is dangerous. → It is dangerous to swim in this river.","My aunt bought me a new bike. → My aunt bought a new bike for me.","She asked me a difficult question. → She asked a difficult question of me.","To read good books is important. → It is important read good books.","He wrote his grandmother a letter. → He wrote a letter to his grandmother."]'::jsonb,4,'가주어 It 구문의 진주어는 to부정사 형태를 유지해야 한다 → It is important to read good books.',true),
(9009,40,2,'어법 종합','다음 중 어법상 <u>틀린</u> 문장끼리 바르게 묶인 것은?

ⓐ I''ll never forget visiting Paris with my family last year.
ⓑ Don''t forget locking the door when you go out tonight.
ⓒ He stopped to eat sweets to lose weight.
ⓓ She tried calling him, but he didn''t answer.
ⓔ Remember to bring your umbrella tomorrow.
ⓕ I gave up to learn the violin.','["ⓐ, ⓒ","ⓑ, ⓒ, ⓕ","ⓑ, ⓓ","ⓒ, ⓔ, ⓕ","ⓐ, ⓓ, ⓕ"]'::jsonb,2,'ⓑ 앞으로 할 일을 잊지 말라는 뜻이므로 forget + to부정사 → to lock. ⓒ 살을 빼려고 ''단것 먹는 것을 그만두었다''는 문맥이므로 stopped eating. ⓕ give up + 동명사 → learning. ⓐ(과거의 경험 → forget -ing), ⓓ(try -ing: 시험 삼아 ~해 보다), ⓔ는 옳다.',true),
(9010,39,2,'어법 판단','다음 중 밑줄 친 that의 쓰임이 <보기>와 같은 것은?

<보기> I didn''t know <u>that</u> the museum was closed on Mondays.','["<u>That</u> tall building is our new library.","The rumor <u>that</u> spread quickly was not true.","Is it true <u>that</u> he moved to Canada?","This bag is bigger than <u>that</u> one.","I don''t like <u>that</u> kind of music."]'::jsonb,3,'<보기>는 목적어 명사절을 이끄는 접속사 that. ③ 가주어 it의 진주어 명사절을 이끄는 접속사 that. ① 지시형용사 ② 관계대명사 ④⑤ 지시대명사/형용사.',true),
(9011,5,2,'빈칸 짝짓기','다음 빈칸에 들어갈 말이 순서대로 바르게 짝지어진 것은?

· Mr. Kim teaches science ______ us on Fridays.
· Could you get a glass of water ______ me?
· May I ask a favor ______ you?
· My uncle showed his new car ______ my family.','["to – for – of – to","for – to – of – to","to – for – to – for","to – to – of – for","for – for – of – to"]'::jsonb,1,'teach/show → to, get(buy, make, cook, find) → for, ask → of.',true),
(9012,4,2,'어법 판단','다음 중 어법상 옳은 것은?','["The pizza smells deliciously, and it tastes well, too.","This scarf feels like silk, and it looks expensively.","Her voice sounded strangely on the phone.","The soup tastes a little salty, but it smells wonderful.","That idea sounds like great to me."]'::jsonb,4,'감각동사 + 형용사 / 감각동사 + like + 명사. ① delicious, good ② expensive ③ strange ⑤ sounds great (like 뒤에는 명사).',true),
(9013,40,2,'빈칸 짝짓기','다음 빈칸 (A), (B)에 들어갈 말이 바르게 짝지어진 것은?

· I''ll send you a message as soon as I (A)[get / will get] to the airport.
· Nobody knows when the next train (B)[arrives / will arrive].','["get – arrives","get – will arrive","will get – arrives","will get – will arrive","got – will arrive"]'::jsonb,2,'(A) as soon as가 이끄는 시간의 부사절 → 현재시제. (B) knows의 목적어인 명사절(''언제 도착할지'') → 미래시제 will arrive.',true),
(9014,15,2,'의미 동일','다음 문장과 의미가 같은 것을 <u>모두</u> 고른 것은?

Seoul is the largest city in Korea.
ⓐ Seoul is larger than any other city in Korea.
ⓑ No other city in Korea is as large as Seoul.
ⓒ Seoul is as large as any other city in Korea.
ⓓ No other city in Korea is larger than Seoul.
ⓔ Other cities in Korea are larger than Seoul.','["ⓐ, ⓑ","ⓐ, ⓑ, ⓓ","ⓑ, ⓒ, ⓓ","ⓐ, ⓒ","ⓒ, ⓔ"]'::jsonb,2,'최상급 = 「비교급 + than any other + 단수명사」 = 「No other + 단수명사 + 비교급 than」 = 「No other + 단수명사 + as 원급 as」. ⓒ는 ''다른 어떤 도시만큼 크다''로 최상급 의미가 아니고, ⓔ는 반대 의미.',true);

insert into grammar_tests (id, label, unit_from, unit_to, question_ids, active) values (901,'내신문법 통합대비 1회',5,40,'[9001,9002,9003,9004,9005,9006,9007,9008,9009,9010,9011,9012,9013,9014]'::jsonb,true);

insert into grammar_written_questions (id, test_id, seq, unit_no, stem, blanks, model_answer, points, explanation) values
(9501,901,15,4,'다음 글에서 어법상 틀린 부분을 <u>세 군데</u> 찾아 바르게 고치시오.

Yesterday my family and I arrived in Ronda, Spain. Most buildings here is white, and they look beautifully against the blue sky. After lunch, we are going to visiting the Hemingway Walk. I''m looking forward to it!','["(1) ______________ → ______________","(2) ______________ → ______________","(3) ______________ → ______________"]'::jsonb,'(1) is → are  (2) beautifully → beautiful  (3) visiting → visit',8,'(1) Most buildings(복수) → are. (2) 감각동사 look + 형용사. (3) be going to + 동사원형. (동아 4과 변형 지문)'),
(9502,901,16,28,'다음 우리말을 <조건>에 맞게 영작하시오.

외국어를 배우는 것은 많은 시간이 걸린다.
<조건> 1. It으로 시작할 것  2. take, learn, a foreign language를 사용할 것  3. 11단어로 쓸 것','["→"]'::jsonb,'It takes a lot of time to learn a foreign language.',7,'가주어 It + takes + 시간 + 진주어 to부정사. (11단어)'),
(9503,901,17,39,'다음 두 문장을 <조건>에 맞게 한 문장으로 쓰시오.

He didn''t get the prize. + I think so.
<조건> 1. 접속사 that을 반드시 쓸 것  2. 부정어는 주절에 한 번만 쓸 것 (I don''t think ~)','["→"]'::jsonb,'I don''t think that he got the prize.',7,'think의 목적어절을 that으로 연결. 부정을 주절로 옮기면 종속절은 긍정 과거형 got.'),
(9504,901,18,33,'다음 우리말과 같은 뜻이 되도록 괄호 안의 단어를 <u>어법에 맞게 변형하여</u> 배열하시오. (필요한 경우 단어의 형태를 바꿀 것)

나는 친구들과 함께 쓰레기를 줍는 것을 즐겼다.
(enjoy / with / pick up / I / trash / my friends)','["→"]'::jsonb,'I enjoyed picking up trash with my friends.',7,'enjoy는 동명사를 목적어로 취한다(pick up → picking up). ''즐겼다''이므로 enjoy → enjoyed. (두 단어 변형이 필요하므로 채점 시 enjoyed/picking 모두 확인)'),
(9505,901,19,15,'다음 표를 보고 <조건>에 맞게 문장을 완성하시오.

Mt. Halla: 1,947m   Mt. Jiri: 1,915m   Mt. Seorak: 1,708m
<조건> 괄호 안의 단어를 이용하고, (3)은 비교급을 사용할 것','["(1) Mt. Halla is ______________ mountain of the three. (high)","(2) Mt. Seorak is ______________ than Mt. Jiri. (low)","(3) No other mountain of the three is ______________ Mt. Halla. (high)"]'::jsonb,'(1) the highest  (2) lower  (3) higher than',8,'(1) the + 최상급 + of the three. (2) 비교급 + than. (3) No other ~ + 비교급 + than = 최상급 의미.'),
(9506,901,20,40,'다음 대화의 빈칸에 괄호 안의 말을 이용하여 알맞은 말을 쓰시오.

A: What are you going to do this weekend?
B: I ________________ my grandmother in Gunsan. (be going to, visit)
A: Sounds nice. Call me when you ________ (get) there.
B: Okay. Oh, can you ________ me your camera? (lend) Mine is broken.','["(1) ______________________","(2) ______________","(3) ______________"]'::jsonb,'(1) am going to visit  (2) get  (3) lend',7,'(1) be going to + 동사원형. (2) 시간 부사절 → 현재시제. (3) 조동사 can + 동사원형, lend + 간접목적어 + 직접목적어.');

insert into grammar_questions (id, unit_no, level, qtype, stem, choices, answer, explanation, active) values
(9015,40,2,'지문 어법','다음 글의 밑줄 친 ⓐ~ⓔ 중 어법상 <u>틀린</u> 것을 <u>모두</u> 고른 것은?

Last summer, I visited my uncle in Alaska. The sun ⓐ <u>doesn''t set</u> from May to July there. One day, my uncle ⓑ <u>took</u> me to the Alaska State Fair. When we ⓒ <u>will arrive</u>, people ⓓ <u>were cutting</u> wood fast. My uncle''s pumpkin was ⓔ <u>more bigger than</u> a pig!','["ⓐ, ⓑ","ⓒ, ⓔ","ⓑ, ⓓ","ⓐ, ⓒ, ⓔ","ⓒ, ⓓ, ⓔ"]'::jsonb,2,'ⓒ 시간 부사절이며 과거의 일 → arrived. ⓔ bigger에 more를 중복해서 쓸 수 없다 → much bigger than. (비상 6과 변형 지문)',true),
(9016,5,2,'어법 판단','다음 중 어법상 옳은 것은?','["Does your brother has a smartphone?","Everyone in my family love spicy food.","Are you know the answer?","One of my cousins lives in Busan.","My parents doesn''t allow me to stay up late."]'::jsonb,4,'① Does ~ have ② Everyone → loves ③ Do you know ⑤ My parents(복수) don''t. ④ one of + 복수명사는 단수 취급 → lives (O).',true),
(9017,32,2,'빈칸 짝짓기','다음 대화의 빈칸 (A)~(C)에 들어갈 말이 바르게 짝지어진 것은?

A: What (A)[do / are] you doing, Mina?
B: I (B)[write / am writing] a letter to my grandma. She is in the hospital.
A: Oh, I''m sorry to hear that. (C)[Does / Is] she getting better?','["do – write – Does","are – am writing – Is","are – write – Does","do – am writing – Is","are – am writing – Does"]'::jsonb,2,'현재진행형: be동사 + -ing. 의문문도 be동사로 시작한다.',true),
(9018,5,2,'어법 판단','다음 중 어법상 <u>틀린</u> 것은?','["There isn''t much sugar left in the jar.","There were a few mistakes in your essay.","Is there anything interesting on TV tonight?","There are a lot of furniture in the room.","There was little rain last month."]'::jsonb,4,'furniture는 셀 수 없는 명사 → There is a lot of furniture.',true),
(9019,18,2,'영작 판단','다음 우리말을 영어로 바르게 옮긴 것은?

그녀는 어젯밤에 집에 없어서 그 소식을 듣지 못했다.','["She wasn''t at home last night, so she didn''t heard the news.","She wasn''t at home last night, so she didn''t hear the news.","She didn''t be at home last night, so she wasn''t hear the news.","She weren''t at home last night, so she didn''t hear the news.","She wasn''t at home last night, so she doesn''t hear the news."]'::jsonb,2,'be동사 과거 부정 wasn''t, 일반동사 과거 부정 didn''t + 동사원형.',true),
(9020,24,2,'의미 동일','다음 중 밑줄 친 부분의 의미가 나머지 넷과 <u>다른</u> 것은?','["You <u>should</u> see a doctor about that cough.","Students <u>should</u> respect their teachers.","We <u>should</u> recycle plastic bottles.","<u>Should</u> I bring anything to the party?","He <u>should</u> be at home by now; he left an hour ago."]'::jsonb,5,'①~④의 should는 의무·충고(~해야 한다). ⑤는 ''~일 것이다''라는 추측의 의미.',true),
(9021,32,2,'어법 개수','다음 중 어법상 옳은 문장의 개수는?

ⓐ Thank you for inviting me to your birthday party.
ⓑ She is worried about make mistakes in front of people.
ⓒ How about go camping this weekend?
ⓓ I''m looking forward to seeing you again.
ⓔ He left the room without saying a word.
ⓕ Learning a new language take a lot of effort.','["1개","2개","3개","4개","5개"]'::jsonb,3,'ⓑ about making ⓒ How about going ⓕ 동명사 주어는 단수 취급 → takes. 옳은 것은 ⓐ, ⓓ, ⓔ 3개.',true),
(9022,28,2,'어법 판단','다음 중 밑줄 친 to부정사의 역할이 <보기>와 같은 것을 <u>모두</u> 고른 것은?

<보기> My dream is <u>to travel</u> around the world by bike.
ⓐ We decided <u>to take</u> the train instead.
ⓑ His job is <u>to protect</u> the environment.
ⓒ <u>To make</u> a good plan is the first step.
ⓓ The most important thing is <u>to be</u> honest.
ⓔ I hope <u>to see</u> you again soon.','["ⓐ, ⓔ","ⓑ, ⓓ","ⓒ","ⓑ, ⓒ, ⓓ","ⓐ, ⓒ, ⓔ"]'::jsonb,2,'<보기>는 주격보어 역할. ⓑⓓ 보어, ⓒ 주어, ⓐⓔ 목적어.',true),
(9023,33,2,'빈칸 짝짓기','다음 빈칸에 들어갈 말이 바르게 짝지어진 것은?

I remember ______ the door this morning, but I forgot ______ the lights. So I have to go back ______ them off.','["to lock – to turn off – to turn","locking – turning off – turning","locking – to turn off – to turn","to lock – turning off – turning","locking – to turn off – turning"]'::jsonb,3,'문을 잠근 것은 이미 한 일 → remember -ing. 불을 끄는 것을 잊은 것은 해야 할 일을 안 한 것 → forget to-v. ''끄기 위해'' 돌아간다 → 목적을 나타내는 to부정사(부사적 용법).',true),
(9024,39,2,'어법 개수','다음 중 that을 생략할 수 <u>있는</u> 문장의 개수는?

ⓐ I hope that you will get better soon.
ⓑ That he is a genius is clear to everyone.
ⓒ We believe that the story is true.
ⓓ The problem is that we don''t have enough time.
ⓔ She knows that I am telling the truth.','["1개","2개","3개","4개","5개"]'::jsonb,3,'목적어절을 이끄는 that(ⓐ, ⓒ, ⓔ)은 생략 가능. 주어절(ⓑ)과 보어절(ⓓ)의 that은 생략하지 않는다.',true),
(9025,3,2,'어법 판단','다음 중 어법상 어색한 것은?','["Could you pass me the salt, please?","She made a beautiful dress for her daughter.","I''ll show my new phone to you after class.","He bought some flowers to his mother.","Ms. Lee told us an interesting story."]'::jsonb,4,'buy는 3형식 전환 시 for → bought some flowers for his mother.',true),
(9026,4,2,'어법 판단','다음 빈칸에 들어갈 수 <u>없는</u> 것은?

The baby looked ______.','["happy","like an angel","sleepily","very tired","hungry"]'::jsonb,3,'감각동사 look 뒤에는 형용사 또는 like + 명사가 온다. 부사 sleepily는 불가.',true),
(9027,40,2,'어법 판단','다음 중 어법상 <u>틀린</u> 것은?','["When you feel tired, take a short break.","I was very young when my family moved to Seoul.","We''ll have a party when the exams are over.","When will the guests arrive at the hotel?","Please turn off the lights when you will leave the room."]'::jsonb,5,'시간의 부사절에서는 미래를 현재시제로 → when you leave. ④의 when은 의문사이므로 will 사용 가능.',true),
(9028,15,2,'어법 종합','다음 중 어법상 옳은 문장끼리 바르게 묶인 것은?

ⓐ This is the most expensive watch in the shop.
ⓑ Health is more important than anything else.
ⓒ She is one of the best player on the team.
ⓓ My room is a lot more clean than yours.
ⓔ The weather is getting worse and worse.','["ⓐ, ⓑ, ⓔ","ⓐ, ⓒ, ⓓ","ⓑ, ⓒ","ⓒ, ⓓ, ⓔ","ⓐ, ⓓ"]'::jsonb,1,'ⓒ one of the + 최상급 + 복수명사 → players. ⓓ clean의 비교급은 cleaner (more clean ×). ⓔ 비교급 and 비교급: 점점 더 ~한.',true);

insert into grammar_tests (id, label, unit_from, unit_to, question_ids, active) values (902,'내신문법 통합대비 2회',5,40,'[9015,9016,9017,9018,9019,9020,9021,9022,9023,9024,9025,9026,9027,9028]'::jsonb,true);

insert into grammar_written_questions (id, test_id, seq, unit_no, stem, blanks, model_answer, points, explanation) values
(9507,902,15,3,'다음 글에서 어법상 틀린 부분을 <u>세 군데</u> 찾아 바르게 고치시오.

This Saturday is my grandma''s birthday. Dad and I will visit her in Gunsan. Usually Mom makes plans for our trips, but this time I will make them. First, I need buying bus tickets. Second, I am going to get a birthday cake to her. Take family photos in a studio will be great, too!','["(1) ______________ → ______________","(2) ______________ → ______________","(3) ______________ → ______________"]'::jsonb,'(1) buying → to buy  (2) to her → for her  (3) Take → Taking',8,'(1) need는 to부정사를 목적어로 취한다. (2) get은 for를 쓰는 수여동사. (3) 문장의 주어 자리 → 동명사 Taking (또는 To take). (미래엔 4과 변형 지문)'),
(9508,902,16,3,'다음 문장을 괄호 안의 지시대로 바꿔 쓰시오.

(1) It is not easy to get up early every day. (To부정사로 시작하는 문장으로)
(2) My grandmother knitted a scarf for me. (4형식 문장으로)','["(1) →","(2) →"]'::jsonb,'(1) To get up early every day is not easy.  (2) My grandmother knitted me a scarf.',8,'(1) 진주어 to부정사구를 주어 자리로. (2) 수여동사 + 간접목적어 + 직접목적어.'),
(9509,902,17,15,'다음 우리말을 <조건>에 맞게 영작하시오.

나는 그가 세계에서 가장 빠른 수영 선수라고 생각한다.
<조건> 1. that, fast, swimmer를 사용할 것  2. 최상급을 사용하여 11단어로 쓸 것','["→"]'::jsonb,'I think that he is the fastest swimmer in the world.',7,'think + that절, the fastest swimmer in the world.'),
(9510,902,18,18,'다음 대화에서 어법상 틀린 부분을 <u>두 군데</u> 찾아 바르게 고치시오.

A: What did you do last weekend?
B: I go to the zoo with my cousin. There was lots of animals.
A: Sounds fun. What was your favorite?
B: The elephants. They looked very smart.','["(1) ______________ → ______________","(2) ______________ → ______________"]'::jsonb,'(1) go → went  (2) was → were',7,'(1) last weekend → 과거시제. (2) lots of animals(복수) → were.'),
(9511,902,19,40,'다음 우리말과 같은 뜻이 되도록 괄호 안의 단어를 <u>어법에 맞게 변형하여</u> 배열하시오. (필요한 경우 단어의 형태를 바꿀 것)

나는 비가 그쳤을 때 개를 산책시킬 것이다.
(the rain / my dog / will / when / I / walk / stop)','["→"]'::jsonb,'I will walk my dog when the rain stops.',7,'시간의 부사절에서 미래는 현재시제로 표현하며, 주어 the rain(3인칭 단수)에 맞춰 stops.'),
(9512,902,20,4,'괄호 안의 단어를 어법에 맞게 변형하여 빈칸을 완성하시오.

(1) He is interested in ________ (make) short videos.
(2) The music sounded ________ (beautiful) in the hall.
(3) My brother ________ (not, eat) breakfast this morning.','["(1) ______________","(2) ______________","(3) ______________"]'::jsonb,'(1) making  (2) beautiful  (3) didn''t eat',7,'(1) 전치사 in + 동명사. (2) 감각동사 + 형용사. (3) this morning → 과거 부정 didn''t + 동사원형.');

insert into grammar_questions (id, unit_no, level, qtype, stem, choices, answer, explanation, active) values
(9029,15,2,'지문 어법','다음 글의 밑줄 친 ⓐ~ⓔ 중 어법상 옳은 것끼리 짝지어진 것은?

Every day, we produce lots of waste, and the Earth ⓐ <u>is getting sicker and sicker</u>. Do you want ⓑ <u>saving</u> the Earth? Then join the zero-waste challenge! My dog tore my bag, so I wanted to buy a new one. But I thought ⓒ <u>that</u> reusing is important, and I decided ⓓ <u>fixing</u> it. I''m not good at ⓔ <u>sewing</u>, but it''s all right.','["ⓐ, ⓑ","ⓐ, ⓒ, ⓔ","ⓑ, ⓓ","ⓒ, ⓓ, ⓔ","ⓐ, ⓓ"]'::jsonb,2,'ⓑ want + to부정사 → to save. ⓓ decide + to부정사 → to fix. ⓐ 비교급 and 비교급, ⓒ 접속사 that, ⓔ 전치사 + 동명사는 옳다. (동아 6과 변형 지문)',true),
(9030,5,2,'어법 개수','다음 중 어법상 <u>틀린</u> 문장의 개수는?

ⓐ The news about the accident were shocking.
ⓑ Both my brother and I are good at swimming.
ⓒ Either you or he have to clean the room.
ⓓ Ten kilometers is a long distance for a child.
ⓔ The police is looking for the missing boy.
ⓕ Some of the water in the bottle was gone.','["1개","2개","3개","4개","5개"]'::jsonb,3,'ⓐ news는 단수 → was. ⓒ either A or B는 B에 수일치 → he has. ⓔ the police는 복수 취급 → are. ⓓ 거리·시간·금액은 단수 취급, ⓕ some of + 불가산 → 단수. 틀린 것은 3개.',true),
(9031,20,2,'어법 판단','다음 중 어법상 옳은 것은?','["I am not understanding this question.","She is having a headache right now.","They are belonging to the tennis club.","He is thinking about his future these days.","Do you knowing his phone number?"]'::jsonb,4,'understand, have(소유·상태), belong, know는 진행형 불가. think는 ''숙고하다''의 의미로 진행형 가능.',true),
(9032,5,2,'빈칸 짝짓기','다음 빈칸 (A)~(C)에 들어갈 말이 바르게 짝지어진 것은?

(A) There [is / are] a lot of homework to do tonight.
(B) [Was / Were] there many people at the concert?
(C) There [isn''t / aren''t] any bread left, so let''s buy some.','["is – Were – isn''t","are – Were – isn''t","is – Was – aren''t","are – Was – aren''t","is – Were – aren''t"]'::jsonb,1,'homework, bread는 셀 수 없는 명사 → is / isn''t. people은 복수 → Were.',true),
(9033,5,2,'대화 어법','다음 대화의 밑줄 친 ①~⑤ 중 어법상 <u>틀린</u> 것은?

A: ① <u>Did you</u> enjoy the trip to Gyeongju?
B: Yes. We ② <u>saw</u> many old temples and ③ <u>took</u> a lot of pictures.
A: ④ <u>Were</u> the weather good?
B: It ⑤ <u>rained</u> a little on the first day, but it was fine after that.','["①","②","③","④","⑤"]'::jsonb,4,'the weather는 단수 → Was the weather good?',true),
(9034,24,2,'어법 판단','다음 중 어법상 옳은 것은?','["Will you can come to my house tomorrow?","She will be able to speak English well soon.","You should not to eat too much sugar.","He is going to studies abroad next year.","They can to solve the problem easily."]'::jsonb,2,'조동사는 나란히 쓸 수 없으므로 will can ×, will be able to (O). 조동사 뒤에는 동사원형: should not eat, is going to study, can solve.',true),
(9035,32,2,'어법 판단','다음 중 밑줄 친 부분의 쓰임(동명사/현재분사)이 나머지 넷과 <u>다른</u> 것은?','["<u>Eating</u> too much fast food is bad for your health.","She finished <u>doing</u> her science homework.","<u>Getting</u> up early is not easy for me.","His favorite activity is <u>playing</u> online games.","We are <u>waiting</u> for the bus at the stop."]'::jsonb,5,'①③ 동명사 주어, ② 동명사 목적어, ④ 동명사 보어로 모두 명사 역할의 동명사. ⑤는 현재진행형을 만드는 현재분사.',true),
(9036,28,2,'문장 전환','다음 문장의 전환이 어법상 옳지 <u>않은</u> 것은?','["To help others is a good thing. → It is a good thing to help others.","To keep a promise is important. → It is important to keep a promise.","It is fun to play board games. → To play board games is fun.","It takes an hour to get there. → To get there is takes an hour.","To exercise every day is healthy. → It is healthy to exercise every day."]'::jsonb,4,'to부정사 주어를 앞으로 옮기면 동사는 하나만 남아야 한다 → To get there takes an hour.',true),
(9037,33,2,'어법 판단','다음 중 밑줄 친 부분이 어법상 <u>틀린</u> 것은?','["I''ll never forget <u>meeting</u> her for the first time.","She stopped <u>eating</u> sweets to lose weight.","We tried <u>to open</u> the window, but it was stuck.","Don''t forget <u>bringing</u> your passport to the airport tomorrow.","He kept <u>talking</u> during the movie."]'::jsonb,4,'내일 해야 할 일 → forget + to부정사 → to bring.',true),
(9038,39,2,'어법 판단','다음 밑줄 친 that절의 역할이 나머지 넷과 <u>다른</u> 것은?','["I believe <u>that he will pass the test</u>.","The truth is <u>that she never called me</u>.","We found out <u>that the store was closed</u>.","He said <u>that he would help us</u>.","Do you think <u>that it will rain tomorrow</u>?"]'::jsonb,2,'②는 be동사 뒤의 보어절. 나머지는 모두 동사의 목적어절.',true),
(9039,5,2,'어법 개수','다음 중 어법상 옳은 문장의 개수는?

ⓐ Could you lend your umbrella to me?
ⓑ My mom cooked us delicious spaghetti.
ⓒ He told the secret for his best friend.
ⓓ Please send an email me by tonight.
ⓔ The teacher asked a difficult question of the students.','["1개","2개","3개","4개","5개"]'::jsonb,3,'ⓒ tell → to. ⓓ send me an email 또는 send an email to me. 옳은 것은 ⓐ, ⓑ, ⓔ 3개.',true),
(9040,4,2,'영작 판단','다음 우리말을 영어로 바르게 옮긴 것은?

그 케이크는 초콜릿 냄새가 나고 맛도 아주 좋다.','["The cake smells like chocolate and tastes really good.","The cake smells chocolate and tastes really well.","The cake smells like chocolate and tastes really well.","The cake smells like chocolate and tastes like really good.","The cake is smelling chocolate and tasting really good."]'::jsonb,1,'감각동사 + like + 명사(chocolate), 감각동사 + 형용사(good).',true),
(9041,40,2,'빈칸 짝짓기','다음 빈칸 (A), (B)에 들어갈 말이 바르게 짝지어진 것은?

· When she (A)[was / will be] a child, she wanted to be a pilot.
· Let''s start the meeting when everyone (B)[comes / will come].','["was – comes","was – will come","will be – comes","will be – will come","is – will come"]'::jsonb,1,'(A) 과거의 일 → was. (B) 시간의 부사절 → 현재시제 comes.',true),
(9042,15,2,'어법 판단','다음 중 어법상 <u>틀린</u> 것은?','["This is the worst movie I have ever seen.","Which is more useful, a laptop or a tablet?","She is the most diligent student in her class.","The Nile is longer than any other river in the world.","Tom is the most tall boy of the three."]'::jsonb,5,'1음절 형용사 tall의 최상급은 tallest → the tallest boy.',true);

insert into grammar_tests (id, label, unit_from, unit_to, question_ids, active) values (903,'내신문법 통합대비 3회',5,40,'[9029,9030,9031,9032,9033,9034,9035,9036,9037,9038,9039,9040,9041,9042]'::jsonb,true);

insert into grammar_written_questions (id, test_id, seq, unit_no, stem, blanks, model_answer, points, explanation) values
(9513,903,15,4,'다음 글에서 어법상 틀린 부분을 <u>세 군데</u> 찾아 바르게 고치시오.

Last summer, my friends and I made our own adventure game. Sujin made the background music, and Jean drew the characters. Every character looked really. Sumin played the game many times and said, "I enjoyed to play it, but it ends too soon." So we added more items. Make a game was hard, but we did it together.','["(1) ______________ → ______________","(2) ______________ → ______________","(3) ______________ → ______________"]'::jsonb,'(1) really → real  (2) to play → playing  (3) Make → Making',8,'(1) 감각동사 look + 형용사. (2) enjoy + 동명사. (3) 주어 자리 → 동명사 Making (To make도 가능). (비상 5과 변형 지문)'),
(9514,903,16,32,'다음 우리말을 <조건>에 맞게 영작하시오.

너는 밤에 혼자 수영하러 가서는 안 된다.
<조건> 1. should, go swimming, alone을 사용할 것  2. 8단어로 쓸 것','["→"]'::jsonb,'You should not go swimming alone at night.',7,'should not + 동사원형, go swimming(go + -ing: ~하러 가다).'),
(9515,903,17,3,'다음 문장을 괄호 안의 지시대로 바꿔 쓰시오.

(1) Mr. Park teaches us math. (전치사를 사용한 3형식 문장으로)
(2) Nothing is more important than health. (최상급을 사용한 문장으로, Health로 시작)','["(1) →","(2) →"]'::jsonb,'(1) Mr. Park teaches math to us.  (2) Health is the most important thing (of all).',8,'(1) teach → to. (2) Nothing is 비교급 than A = A is the 최상급.'),
(9516,903,18,33,'다음 대화의 빈칸에 괄호 안의 말을 이용하여 알맞은 말을 쓰시오.

A: What ________ you ________ (do) now?
B: I''m ________ (look) for my keys. I remember ________ (put) them on the desk, but they''re not there.','["(1) ______________ / ______________","(2) ______________","(3) ______________"]'::jsonb,'(1) are / doing  (2) looking  (3) putting',7,'(1)(2) 현재진행형. (3) 과거에 한 일을 기억 → remember + 동명사.'),
(9517,903,19,39,'다음 우리말과 같은 뜻이 되도록 괄호 안의 단어를 <u>어법에 맞게 변형하여</u> 배열하시오. (필요한 경우 단어의 형태를 바꿀 것)

그가 약속을 지키지 않았다는 것은 사실이다.
(it / that / true / keep / he / didn''t / is / his promise)','["→"]'::jsonb,'It is true that he didn''t keep his promise.',7,'가주어 It + is true + 진주어 that절. didn''t 뒤에는 동사원형 keep (변형 없음) — 배열 문제로 채점 시 어순 확인.'),
(9518,903,20,15,'괄호 안의 단어를 어법에 맞게 변형하여 빈칸을 완성하시오.

(1) There ________ (be) two bottles of water on the table yesterday.
(2) My sister is much ________ (good) at cooking than I am.
(3) We look forward to ________ (see) you at the festival.','["(1) ______________","(2) ______________","(3) ______________"]'::jsonb,'(1) were  (2) better  (3) seeing',7,'(1) two bottles(복수) + yesterday → were. (2) good의 비교급 better, much로 강조. (3) look forward to + 동명사.');

insert into grammar_questions (id, unit_no, level, qtype, stem, choices, answer, explanation, active) values
(9043,3,2,'지문 어법','다음 글의 밑줄 친 ⓐ~ⓔ 중 어법상 <u>틀린</u> 것의 개수는?

Today is the first day of the zero-waste challenge. Jiwoo ⓐ <u>gave some advice to me</u>. She said, "ⓑ <u>Know</u> your trash is very important." So I went through my garbage. I ⓒ <u>was throwing away</u> too much plastic! I ⓓ <u>should not be</u> so wasteful. It was hot today, so Dad ⓔ <u>bought me lemonade</u>. It came with a straw, but I said, "No straw, please."','["0개","1개","2개","3개","4개"]'::jsonb,2,'ⓑ 주어 자리에는 동사원형이 올 수 없다 → Knowing (동명사). ⓐ give → to (O), ⓒ 과거진행형, ⓓ should not + 동사원형, ⓔ 4형식 buy는 모두 옳다. (미래엔 5과 변형 지문)',true),
(9044,5,2,'어법 종합','다음 중 어법상 옳은 것끼리 바르게 묶인 것은?

ⓐ Every boy and girl in the class knows the song.
ⓑ Neither of the answers are correct.
ⓒ The rich is not always happy.
ⓓ A pair of shoes is on the floor.
ⓔ The number of cars in the city is growing.','["ⓐ, ⓓ","ⓐ, ⓑ, ⓔ","ⓑ, ⓒ","ⓒ, ⓓ, ⓔ","ⓐ, ⓓ, ⓔ"]'::jsonb,5,'ⓑ neither of ~는 단수 취급 → is. ⓒ the + 형용사(~한 사람들)는 복수 → are. ⓔ the number of ~는 단수 취급(O).',true),
(9045,32,2,'어법 판단','다음 중 밑줄 친 부분이 어법상 <u>틀린</u> 것은?','["The children <u>are lying</u> on the grass.","My mom <u>is cutting</u> the vegetables now.","<u>Are</u> you <u>hearing</u> the strange noise?","I <u>am having</u> lunch with my friends.","She <u>is dyeing</u> her hair red."]'::jsonb,3,'hear는 지각 상태동사로 진행형 불가 → Do you hear ~? ⑤ dye → dyeing (O, 철자 주의: dying은 die의 -ing형).',true),
(9046,18,2,'영작 판단','다음 우리말을 영어로 바르게 옮긴 것은?

교실에 학생이 몇 명 있었나요? — 아니요, 아무도 없었어요.','["Was there any students in the classroom? — No, there wasn''t.","Were there any students in the classroom? — No, there weren''t.","Were there any student in the classroom? — No, there were.","Did there any students in the classroom? — No, there didn''t.","There were any students in the classroom? — No, there weren''t."]'::jsonb,2,'There is/are 과거 의문문: Were there + 복수명사 ~? 대답: No, there weren''t.',true),
(9047,5,2,'어법 개수','다음 중 어법상 옳은 문장의 개수는?

ⓐ She didn''t came to the party last night.
ⓑ When did you lose your wallet?
ⓒ We weren''t hungry, so we didn''t eat anything.
ⓓ Did he studied hard for the test?
ⓔ The concert began at seven and finished at nine.','["1개","2개","3개","4개","5개"]'::jsonb,3,'ⓐ didn''t come ⓓ Did he study. 옳은 것은 ⓑ, ⓒ, ⓔ 3개.',true),
(9048,24,2,'빈칸 짝짓기','다음 빈칸에 들어갈 말이 바르게 짝지어진 것은?

A: Look at those dark clouds. It ______ rain soon.
B: Then we ______ take an umbrella.','["will be – can''t","is going to – should","is going – shouldn''t","was going to – should","can – will be"]'::jsonb,2,'근거가 있는 예측 → be going to + 동사원형. 충고 → should.',true),
(9049,32,2,'어법 판단','다음 <보기>의 밑줄 친 부분과 문장 내 역할(전치사의 목적어)이 같은 것은?

<보기> I''m sorry for <u>being</u> late.','["The children are <u>being</u> very noisy today.","<u>Being</u> honest is the most important thing.","She was <u>being</u> silly at the party.","Thank you for <u>being</u> my friend.","He is <u>being</u> careful with the glass."]'::jsonb,4,'<보기>는 전치사 for의 목적어인 동명사. ④ for being (전치사의 목적어). ② 동명사 주어(명사 역할이지만 전치사 목적어는 아님). ①③⑤는 진행형.',true),
(9050,28,2,'어법 판단','다음 중 어법상 <u>틀린</u> 것은?','["It is impossible to finish this today.","To learn from mistakes is important.","My plan is to save money for a trip.","He wants to not miss the train.","She promised to call me tonight."]'::jsonb,4,'to부정사의 부정은 not to + 동사원형 → wants not to miss (자연스러운 표현은 doesn''t want to miss).',true),
(9051,33,2,'빈칸 짝짓기','다음 빈칸 (A)~(C)에 들어갈 말이 바르게 짝지어진 것은?

· She tried (A)[to open / opening] the jar, but she couldn''t.
· I stopped (B)[to buy / buying] some snacks on my way home.
· Would you mind (C)[to close / closing] the door?','["to open – to buy – closing","opening – buying – closing","to open – buying – to close","opening – to buy – closing","to open – to buy – to close"]'::jsonb,1,'(A) ''열려고 애썼지만'' → try to-v. (B) ''사기 위해 멈췄다'' → stop to-v (부사적 용법). (C) mind + 동명사.',true),
(9052,39,2,'어법 판단','다음 중 that이 들어갈 위치로 알맞은 곳은?

I ① heard ② the ③ new ④ restaurant ⑤ is very popular.','["①","②","③","④","⑤"]'::jsonb,2,'heard의 목적어절(the new restaurant is very popular)을 이끄는 접속사 that은 절 앞(②)에 온다.',true),
(9053,5,2,'문장 전환','다음 문장의 전환이 어법상 옳은 것은?','["She gave me some advice. → She gave some advice for me.","He made us a big pizza. → He made a big pizza to us.","I''ll write you a long letter. → I''ll write a long letter to you.","Can you find me my glasses? → Can you find my glasses to me?","Dad bought my sister a doll. → Dad bought a doll of my sister."]'::jsonb,3,'write → to (O). ① give → to ② make → for ④ find → for ⑤ buy → for.',true),
(9054,4,2,'어법 개수','다음 중 어법상 옳은 문장의 개수는?

ⓐ This medicine tastes bitterly.
ⓑ Your idea sounds interesting.
ⓒ The room smelled like fresh flowers.
ⓓ He looked at the picture carefully.
ⓔ I feel sleepily after lunch.','["1개","2개","3개","4개","5개"]'::jsonb,3,'ⓐ bitter ⓔ sleepy. ⓓ look at은 일반동사이므로 부사 carefully가 옳다. 옳은 것은 ⓑ, ⓒ, ⓓ 3개.',true),
(9055,40,2,'어법 판단','다음 두 문장을 when으로 연결한 것 중 어법상 옳은 것은?

I will call you. + I will get to the station.','["I will call you when I will get to the station.","I will call you when I get to the station.","I call you when I will get to the station.","When I will get to the station, I call you.","When I got to the station, I will call you."]'::jsonb,2,'주절은 미래, 시간의 부사절은 현재시제.',true),
(9056,15,2,'의미 동일','다음 중 의미가 나머지 넷과 <u>다른</u> 것은?','["Jenny is taller than any other girl in her class.","No other girl in Jenny''s class is taller than Jenny.","Jenny is the tallest girl in her class.","No other girl in Jenny''s class is as tall as Jenny.","Jenny is as tall as any other girl in her class."]'::jsonb,5,'⑤는 ''다른 여학생만큼 크다''는 원급 비교로 최상급 의미가 아니다.',true);

insert into grammar_tests (id, label, unit_from, unit_to, question_ids, active) values (904,'내신문법 통합대비 4회',5,40,'[9043,9044,9045,9046,9047,9048,9049,9050,9051,9052,9053,9054,9055,9056]'::jsonb,true);

insert into grammar_written_questions (id, test_id, seq, unit_no, stem, blanks, model_answer, points, explanation) values
(9519,904,15,15,'다음 글에서 어법상 틀린 부분을 <u>세 군데</u> 찾아 바르게 고치시오.

We got hungry, so we go to the food court and had salmon sandwiches. They were very new to me. Then we went to the Giant Vegetable Contest. All the vegetables was huge! My uncle''s pumpkin was bigger than a pig. "The crops get 20 hours of sunlight a day, so they grow bigger and more sweet," my uncle said.','["(1) ______________ → ______________","(2) ______________ → ______________","(3) ______________ → ______________"]'::jsonb,'(1) go → went  (2) was → were  (3) more sweet → sweeter',8,'(1) 과거시제 일치. (2) All the vegetables(복수) → were. (3) sweet의 비교급은 sweeter. (비상 6과 변형 지문)'),
(9520,904,16,3,'다음 문장을 괄호 안의 지시대로 바꿔 쓰시오.

(1) She asked her teacher a question. (전치사를 사용한 3형식 문장으로)
(2) I think. + He is telling a lie. (that을 사용해 한 문장으로, 부정은 주절에)','["(1) →","(2) →"]'::jsonb,'(1) She asked a question of her teacher.  (2) I don''t think that he is telling a lie.',8,'(1) ask → of. (2) I don''t think that ~.'),
(9521,904,17,32,'다음 우리말을 <조건>에 맞게 영작하시오.

매일 아침을 먹는 것은 건강에 좋다.
<조건> 1. 동명사를 주어로 쓸 것  2. eat, breakfast, good for, health를 사용할 것  3. 9단어로 쓸 것','["→"]'::jsonb,'Eating breakfast every day is good for your health.',7,'동명사 주어는 단수 취급 → is. (9단어)'),
(9522,904,18,4,'다음 대화의 빈칸에 괄호 안의 말을 이용하여 알맞은 말을 쓰시오.

A: Why don''t we go hiking this weekend?
B: Sorry, I can''t. I ________________ (be going to, visit) my aunt in Daegu.
A: Okay. Then let''s go when you ________ (come) back.
B: Sure. It ________ (sound) great.','["(1) ______________________","(2) ______________","(3) ______________"]'::jsonb,'(1) am going to visit  (2) come  (3) sounds',7,'(1) be going to + 동사원형. (2) 시간 부사절 현재시제. (3) 3인칭 단수 현재 sounds + 형용사.'),
(9523,904,19,15,'다음 우리말과 같은 뜻이 되도록 괄호 안의 단어를 <u>어법에 맞게 변형하여</u> 배열하시오. (필요한 경우 단어의 형태를 바꿀 것)

이 문제는 저 문제보다 훨씬 더 어렵다.
(much / this question / that one / is / than / difficult)','["→"]'::jsonb,'This question is much more difficult than that one.',7,'difficult의 비교급은 more difficult, much는 비교급 강조.'),
(9524,904,20,33,'괄호 안의 단어를 어법에 맞게 변형하여 빈칸을 완성하시오.

(1) Would you mind ________ (turn) down the music?
(2) He forgot ________ (bring) his homework, so he went back home to get it.
(3) The number of cars on the road ________ (be) increasing.','["(1) ______________","(2) ______________","(3) ______________"]'::jsonb,'(1) turning  (2) to bring  (3) is',7,'(1) mind + 동명사. (2) 가져와야 할 것을 잊음 → forget to-v. (3) the number of ~ → 단수.');

insert into grammar_questions (id, unit_no, level, qtype, stem, choices, answer, explanation, active) values
(9057,32,2,'지문 어법','다음 글의 밑줄 친 ⓐ~ⓔ 중 어법상 <u>틀린</u> 것을 <u>모두</u> 고른 것은?

I''m on Purple Island in Korea. Almost everything here ⓐ <u>are</u> purple - the houses, the buses, and even the bridges. Purple is my favorite color, so the island ⓑ <u>is</u> just perfect for me. I didn''t even pay the entrance fee. Why? Because I ⓒ <u>was wearing</u> a purple T-shirt! Tomorrow I''m going ⓓ <u>to get up</u> early and enjoy ⓔ <u>to walk</u> along the purple streets.','["ⓐ, ⓔ","ⓑ, ⓒ","ⓐ, ⓒ, ⓔ","ⓒ, ⓓ","ⓓ, ⓔ"]'::jsonb,1,'ⓐ everything은 단수 취급 → is. ⓔ enjoy + 동명사 → walking. (동아 4과 변형 지문)',true),
(9058,5,2,'어법 판단','다음 중 어법상 옳은 것은?','["A number of students was absent today.","The number of visitors are growing fast.","Each of my friends have a different hobby.","Some of the apples in the box were rotten.","One of the most popular sports are soccer."]'::jsonb,4,'① a number of → 복수 were ② the number of → 단수 is ③ each of → 단수 has ⑤ one of ~ → 단수 is. ④ some of + 복수명사 → 복수 (O).',true),
(9059,20,2,'빈칸 짝짓기','다음 대화의 빈칸에 들어갈 말이 바르게 짝지어진 것은?

A: Where''s Dad? ______ he ______ the car again?
B: No, he ______ in the garden now.','["Is – washing – is reading","Does – wash – reads","Is – washing – reads","Does – washing – is reading","Is – wash – is reading"]'::jsonb,1,'현재진행형 의문문 Is he washing ~? / 대답 he is reading.',true),
(9060,5,2,'어법 판단','다음 중 어법상 <u>틀린</u> 것은?','["There is a lot of traffic on the road today.","There were some good news in the letter.","Is there anyone at the door?","There weren''t many people at the park.","There was an old castle on the hill."]'::jsonb,2,'news는 셀 수 없는 명사 → There was some good news.',true),
(9061,18,2,'대화 어법','다음 대화의 밑줄 친 ①~⑤ 중 어법상 <u>틀린</u> 것은?

A: Who ① <u>broke</u> the window? ② <u>Did</u> you ③ <u>do</u> it?
B: No, I ④ <u>didn''t</u>. I ⑤ <u>weren''t</u> even here this morning.','["①","②","③","④","⑤"]'::jsonb,5,'주어 I의 be동사 과거 부정 → wasn''t.',true),
(9062,24,2,'어법 개수','다음 중 어법상 옳은 문장의 개수는?

ⓐ You must not to park here.
ⓑ Should I bring my own lunch tomorrow?
ⓒ We are going to have a picnic if it is sunny.
ⓓ She will can join us later.
ⓔ He is going to not come to the meeting.','["1개","2개","3개","4개","5개"]'::jsonb,2,'ⓐ must not park ⓓ will be able to join ⓔ is not going to come. 옳은 것은 ⓑ, ⓒ 2개.',true),
(9063,32,2,'어법 판단','다음 중 밑줄 친 부분의 쓰임이 나머지 넷과 <u>다른</u> 것은?','["<u>Baking</u> cookies is my favorite weekend activity.","She is good at <u>drawing</u> cartoons.","My job is <u>helping</u> sick animals.","I stopped <u>running</u> because I was tired.","The boy <u>standing</u> over there is my brother."]'::jsonb,5,'⑤는 명사 The boy를 수식하는 현재분사. 나머지는 동명사(주어·전치사 목적어·보어·동사 목적어).',true),
(9064,28,2,'어법 판단','다음 중 어법상 옳은 것을 <u>모두</u> 고른 것은?

ⓐ It is important to not give up.
ⓑ It was hard to find a parking space.
ⓒ My hope is to travel to space someday.
ⓓ To read in the dark are bad for your eyes.
ⓔ We decided to not tell anyone.','["ⓐ, ⓔ","ⓑ, ⓒ","ⓑ, ⓒ, ⓓ","ⓐ, ⓑ, ⓒ","ⓒ, ⓓ, ⓔ"]'::jsonb,2,'ⓐⓔ to부정사의 부정은 not to-v. ⓓ to부정사 주어는 단수 취급 → is.',true),
(9065,33,2,'어법 판단','다음 중 밑줄 친 부분의 의미가 바르게 해석되지 <u>않은</u> 것은?','["I remember <u>seeing</u> him at the party. – 그를 봤던 것을 기억한다","Remember <u>to see</u> the doctor tomorrow. – 내일 의사를 만날 것을 기억해라","She tried <u>to lift</u> the box. – 시험 삼아 상자를 들어 보았다","He stopped <u>smoking</u> last year. – 작년에 담배 피우는 것을 끊었다","I forgot <u>to send</u> the email. – 이메일을 보내야 하는 것을 잊었다"]'::jsonb,3,'try + to부정사는 ''~하려고 애쓰다''. ''시험 삼아 ~해 보다''는 try + 동명사(tried lifting).',true),
(9066,39,2,'어법 판단','다음 빈칸에 that이 들어갈 수 <u>없는</u> 것은?','["I can''t believe ______ she is already twenty.","The good news is ______ we won the game.","______ he is a good singer is true.","I wonder ______ he will come or not.","Everyone knows ______ the Earth goes around the Sun."]'::jsonb,4,'''~인지 아닌지''는 whether/if를 쓴다. 나머지는 명사절 접속사 that.',true),
(9067,5,2,'문장 전환','다음 중 문장 전환이 어법상 옳지 <u>않은</u> 것은?','["He handed me the report. → He handed the report to me.","She cooked us a big dinner. → She cooked a big dinner for us.","They showed the tourists the way. → They showed the way to the tourists.","I asked him his name. → I asked his name to him.","Mom bought me a new coat. → Mom bought a new coat for me."]'::jsonb,4,'ask는 of → asked his name of him.',true),
(9068,4,2,'어법 판단','다음 중 어법상 <u>틀린</u> 것은?','["The leaves feel dry and rough.","This perfume smells like roses.","The plan sounds like a lot of fun.","The soup tastes too salty for me.","He looks like tired after the game."]'::jsonb,5,'형용사 tired 앞에는 like를 쓰지 않는다 → looks tired.',true),
(9069,40,2,'어법 판단','다음 중 어법상 옳은 것은?','["I don''t know when will he come back.","When I will finish my homework, I will watch TV.","She was sleeping when I will call her.","Let''s go out when the rain stops.","I''ll wait here until you will come."]'::jsonb,4,'① 간접의문문 어순 when he will come back. ② when I finish ③ when I called ⑤ until you come. 시간의 부사절(when, until)은 현재시제.',true),
(9070,5,2,'어법 개수','다음 중 어법상 옳은 문장의 개수는?

ⓐ Your bag is much heavier than mine.
ⓑ This is the more interesting book of all.
ⓒ He runs the fastest in our school.
ⓓ Which is bigger, the Sun or the Earth?
ⓔ Nothing is as more important as family.','["1개","2개","3개","4개","5개"]'::jsonb,3,'ⓑ of all(셋 이상) → the most interesting. ⓔ as + 원급 + as → as important as. 옳은 것은 ⓐ, ⓒ, ⓓ 3개.',true);

insert into grammar_tests (id, label, unit_from, unit_to, question_ids, active) values (905,'내신문법 통합대비 5회',5,40,'[9057,9058,9059,9060,9061,9062,9063,9064,9065,9066,9067,9068,9069,9070]'::jsonb,true);

insert into grammar_written_questions (id, test_id, seq, unit_no, stem, blanks, model_answer, points, explanation) values
(9525,905,15,15,'다음 글에서 어법상 틀린 부분을 <u>세 군데</u> 찾아 바르게 고치시오.

Last Friday, a young man came into my bakery. I spoke to him in Spanish, but he didn''t understood me. He spoke only English. I showed him a lot of different cakes, but he just wanted the most small one. We sold only one cake that day, so I remember to see him clearly.','["(1) ______________ → ______________","(2) ______________ → ______________","(3) ______________ → ______________"]'::jsonb,'(1) understood → understand  (2) the most small → the smallest  (3) to see → seeing',8,'(1) didn''t + 동사원형. (2) 1음절 형용사의 최상급 -est. (3) 과거에 본 것을 기억 → remember + 동명사. (동아 5과 변형 지문)'),
(9526,905,16,3,'다음 문장을 괄호 안의 지시대로 바꿔 쓰시오.

(1) To keep early hours is good for your health. (가주어 It을 사용한 문장으로)
(2) My uncle gave a nice present to me. (4형식 문장으로)','["(1) →","(2) →"]'::jsonb,'(1) It is good for your health to keep early hours.  (2) My uncle gave me a nice present.',8,'(1) It + is + 형용사구 + to부정사. (2) give + 간접목적어 + 직접목적어.'),
(9527,905,17,15,'다음 우리말을 <조건>에 맞게 영작하시오.

나는 그 시험이 내가 예상했던 것보다 훨씬 더 쉬웠다고 생각한다.
<조건> 1. that, much, easy, expect를 사용할 것  2. 11단어로 쓸 것','["→"]'::jsonb,'I think that the test was much easier than I expected.',7,'think + that절, much + 비교급(easier) + than I expected. (11단어)'),
(9528,905,18,4,'다음 대화의 빈칸에 괄호 안의 말을 이용하여 알맞은 말을 쓰시오.

A: How was the food at the new restaurant?
B: It ________ (look) great, but it ________ (taste) terrible.
A: That''s too bad. ________ there many people? (be)
B: No, there ________ (be, not) anyone but us.','["(1) ______________ / ______________","(2) ______________","(3) ______________"]'::jsonb,'(1) looked / tasted  (2) Were  (3) wasn''t',7,'(1) 과거시제, 감각동사 + 형용사. (2) many people → Were there. (3) anyone(단수) → there wasn''t anyone.'),
(9529,905,19,33,'다음 우리말과 같은 뜻이 되도록 괄호 안의 단어를 <u>어법에 맞게 변형하여</u> 배열하시오. (필요한 경우 단어의 형태를 바꿀 것)

그녀는 그 노래를 부르는 것을 그만두고 무대를 떠났다.
(the song / she / and / stop / the stage / sing / left)','["→"]'::jsonb,'She stopped singing the song and left the stage.',7,'stop + 동명사(~하는 것을 멈추다). stop → stopped, sing → singing (두 단어 변형 필요, 채점 시 확인).'),
(9530,905,20,40,'괄호 안의 단어를 어법에 맞게 변형하여 빈칸을 완성하시오.

(1) Everyone in my class ________ (like) our new teacher.
(2) I''ll text you when I ________ (arrive) at the hotel.
(3) Tom is ________ (bad) at math than his brother, but he is the ________ (good) at English in his class.','["(1) ______________","(2) ______________","(3) ______________ / ______________"]'::jsonb,'(1) likes  (2) arrive  (3) worse / best',7,'(1) everyone → 단수 likes. (2) 시간 부사절 현재시제. (3) bad–worse–worst, good–better–best.');

select setval(pg_get_serial_sequence('grammar_questions','id'), (select max(id) from grammar_questions));
select setval(pg_get_serial_sequence('grammar_tests','id'), (select max(id) from grammar_tests));
select setval(pg_get_serial_sequence('grammar_written_questions','id'), (select max(id) from grammar_written_questions));
-- 완료: naesin.html 의 CONFIG.TEST_LABEL_PREFIX = '내신문법 통합대비' 로 5개 시험지가 자동 표시됩니다.