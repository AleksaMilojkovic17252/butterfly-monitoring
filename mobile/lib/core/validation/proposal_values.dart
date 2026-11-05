// The allowed values of a route proposal (V07). They must stay the same as the
// `ProposalReason` and `ProposalStatus` choices in
// `backend/apps/transects/models.py`.

/// Why a route is proposed: the server's value and the label the screens show.
const proposalReasons = <String, String>{
  'private_property': 'Private property',
  'unsafe': 'Unsafe',
  'impassable': 'Impassable',
  'better_route': 'Better route',
  'other': 'Other',
};

/// The label of reason [value]; an unknown value is shown as it is.
String proposalReasonLabel(String value) => proposalReasons[value] ?? value;

/// The label of a proposal status: "Pending", "Accepted" or "Rejected".
String proposalStatusLabel(String status) => switch (status) {
  'pending' => 'Pending',
  'accepted' => 'Accepted',
  'rejected' => 'Rejected',
  _ => status,
};
