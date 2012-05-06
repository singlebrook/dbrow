alter table tblArthropod add legs integer;
alter table tblArthropod add venemous boolean;

create table tblSubphylum (
  subphylumID serial primary key,
  subphylum_name varchar(50)
);

alter table tblArthropod
add subphylumID integer
references tblSubphylum(subphylumID)
on update cascade
on delete cascade;
