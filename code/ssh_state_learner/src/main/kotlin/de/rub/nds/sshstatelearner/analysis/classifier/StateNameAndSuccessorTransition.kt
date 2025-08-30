package de.rub.nds.sshstatelearner.analysis.classifier

import de.rub.nds.sshstatelearner.extraction.SshSymbol

data class StateNameAndSuccessorTransition(
    val stateName: String = "",
    val successorTransition: SshSymbol? = null
)