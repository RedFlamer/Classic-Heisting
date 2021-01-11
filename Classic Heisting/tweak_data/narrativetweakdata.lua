local data = NarrativeTweakData.init
function NarrativeTweakData:init(tweak_data)
	data(self, tweak_data)

	self.jobs.firestarter_prof = deep_clone(self.jobs.firestarter)
	self.jobs.firestarter_prof.jc = 70
	self.jobs.firestarter_prof.professional = true
	self.jobs.firestarter_prof.region = "professional"
	self.jobs.firestarter_prof.payout = {
		80000,
		110000,
		160000,
		250000,
		300000
	}
	self.jobs.firestarter_prof.heat = {this_job = -25, other_jobs = 30}

	self.jobs.alex_prof = deep_clone(self.jobs.alex)
	self.jobs.alex_prof.jc = 70
	self.jobs.alex_prof.professional = true
	self.jobs.alex_prof.region = "professional"
	self.jobs.alex_prof.payout = {
		10000,
		15000,
		30000,
		40000,
		80000
	}
	self.jobs.alex_prof.contract_cost = {
		131000,
		188000,
		264000,
		530000,
		700000
	}
	self.jobs.alex_prof.heat = {this_job = -35, other_jobs = 10}

	self.jobs.welcome_to_the_jungle_prof = deep_clone(self.jobs.welcome_to_the_jungle)
	self.jobs.welcome_to_the_jungle_prof.jc = 70
	self.jobs.welcome_to_the_jungle_prof.professional = true
	self.jobs.welcome_to_the_jungle_prof.region = "professional"
	self.jobs.welcome_to_the_jungle_prof.payout = {
		250000,
		300000,
		450000,
		550000,
		850000
	}
	self.jobs.welcome_to_the_jungle_prof.contract_cost = {
		-100000,
		-300000,
		-550000,
		-850000,
		-1200000
	}
	self.jobs.welcome_to_the_jungle_prof.heat = {this_job = -25, other_jobs = 30}

	self.jobs.framing_frame_prof = deep_clone(self.jobs.framing_frame)
	self.jobs.framing_frame_prof.jc = 60
	self.jobs.framing_frame_prof.professional = true
	self.jobs.framing_frame_prof.region = "professional"
	self.jobs.framing_frame_prof.payout = {
		80000,
		100000,
		150000,
		200000,
		300000
	}
	self.jobs.framing_frame_prof.heat = {this_job = -25, other_jobs = 30}

	self.jobs.watchdogs_prof = deep_clone(self.jobs.watchdogs)
	self.jobs.watchdogs_prof.jc = 60
	self.jobs.watchdogs_prof.professional = true
	self.jobs.watchdogs_prof.payout = {
		75000,
		85000,
		150000,
		200000,
		290000
	}
	self.jobs.watchdogs_prof.heat = {this_job = -25, other_jobs = 20}

	self.jobs.ukrainian_job_prof = deep_clone(self.jobs.ukrainian_job)
	self.jobs.ukrainian_job_prof.jc = 30
	self.jobs.ukrainian_job_prof.professional = true
	self.jobs.ukrainian_job_prof.region = "professional"
	self.jobs.ukrainian_job_prof.payout = {
		21000,
		24000,
		26000,
		30000,
		40000
	}
	self.jobs.ukrainian_job_prof.heat = {this_job = -30, other_jobs = 10}

	self.jobs.branchbank_prof = deep_clone(self.jobs.branchbank)
	self.jobs.branchbank_prof.jc = 50
	self.jobs.branchbank_prof.professional = true
	self.jobs.branchbank_prof.region = "professional"
	self.jobs.branchbank_prof.payout = {
		26000,
		40000,
		48000,
		70000,
		85000
	}
	
	self.jobs.branchbank_gold_prof = deep_clone(self.jobs.branchbank_gold)
	self.jobs.branchbank_gold_prof.jc = 30
	self.jobs.branchbank_gold_prof.professional = true
	self.jobs.branchbank_gold_prof.region = "professional"
	self.jobs.branchbank_gold_prof.payout = {
		26000,
		40000,
		54000,
		76000,
		90000
	}
	
	self._jobs_index = {
		"welcome_to_the_jungle_prof",
		"framing_frame",
		"framing_frame_prof",
		"watchdogs",
		"watchdogs_prof",
		"alex",
		"alex_prof",
		"firestarter",
		"firestarter_prof",
		"ukrainian_job_prof",
		"jewelry_store",
		"four_stores",
		"nightclub",
		"mallcrasher",
		"branchbank_deposit",
		"branchbank_cash",
		"branchbank_gold_prof",
		"branchbank_prof",
		"family",
		"roberts",
		"arm_fac",
		"arm_par",
		"arm_hcm",
		"arm_und",
		"arm_cro"
	}
end