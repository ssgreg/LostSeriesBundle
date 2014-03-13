import pymongo
import datetime

client = pymongo.MongoClient()

db = client['test-database']

ids = db.ids

#ids.remove({"token": "99c2a09abce108cdea3a09c309323926a24b68dfbc78b790b28c520e93ff61fd"})

for idc in ids.find({"token": "99c2a09abce108cdea3a09c309323926a24b68dfbc78b790b28c520e93ff61fd"}):
  print idc

post = \
{
  "token": "99c2a09abce108cdea3a09c309323926a24b68dfbc78b790b28c520e93ff61fd",
  "date": datetime.datetime.utcnow(),
  "tags": ["Arrow", "The Vampire Diaries"],
}

#ids.insert(post)

#print ids.find_one({"token": "99c2a09abce108cdea3a09c309323926a24b68dfbc78b790b28c520e93ff61fd"})